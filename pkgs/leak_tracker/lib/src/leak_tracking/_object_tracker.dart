// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

import '../shared/shared_model.dart';
import '_leak_filter.dart';
import '_object_record.dart';
import '_object_records.dart';
import 'primitives/_finalizer.dart';
import 'primitives/_gc_counter.dart';
import 'primitives/_retaining_path/_connection.dart';
import 'primitives/_retaining_path/_retaining_path.dart';
import 'primitives/model.dart';

/// Keeps collection of object records until
/// disposal and garbage collection.
///
/// If disposal and garbage collection happened abnormally,
/// marks the object as leaked.
class ObjectTracker implements LeakProvider {
  /// The optional parameters are injected for testing purposes.
  ObjectTracker({
    required this.disposalTime,
    required this.numberOfGcCycles,
    required this.maxRequestsForRetainingPath,
    FinalizerBuilder? finalizerBuilder,
    GcCounter? gcCounter,
  }) {
    finalizerBuilder ??= buildStandardFinalizer;
    _finalizer = finalizerBuilder(_onObjectGarbageCollected);
    _gcCounter = gcCounter ?? GcCounter();
  }

  /// Time to allow the disposal invoker to release the reference to the object.
  final Duration disposalTime;

  late FinalizerWrapper _finalizer;

  late GcCounter _gcCounter;

  final _objects = ObjectRecords();

  late final _leakFilter = LeakFilter();

  bool disposed = false;

  final int numberOfGcCycles;

  final int? maxRequestsForRetainingPath;

  void startTracking(
    Object object, {
    required Map<String, dynamic>? context,
    required String trackedClass,
    required PhaseSettings phase,
  }) {
    throwIfDisposed();
    if (phase.ignoreLeaks) return;

    final (:record, :wasAbsent) =
        _objects.notGCed.putIfAbsent(object, context, phase, trackedClass);

    if (!wasAbsent) return;

    if (phase.leakDiagnosticConfig.collectStackTraceOnStart) {
      record.setContext(ContextKeys.startCallstack, StackTrace.current);
    }

    _finalizer.attach(object, record);

    _objects.assertRecordIntegrity(record);
  }

  void _onObjectGarbageCollected(Object record) {
    if (disposed) return;
    if (record is! ObjectRecord) {
      throw Exception('record should be $ObjectRecord');
    }

    _objects.assertRecordIntegrity(record);
    record.setGCed(_gcCounter.gcCount, clock.now());

    _declareNotDisposedLeak(record);
  }

  void _declareNotDisposedLeak(ObjectRecord record) {
    if (record.isGCedLateLeak(disposalTime, numberOfGcCycles)) {
      _objects.gcedLateLeaks.add(record);
    } else if (!record.isDisposed) {
      _objects.gcedNotDisposedLeaks.add(record);
    }

    _objects.notGCed.remove(record);
    _objects.notGCedDisposedOk.remove(record);
    _objects.notGCedDisposedLate.remove(record);
    _objects.notGCedDisposedLateCollected.remove(record);

    _objects.assertRecordIntegrity(record);
  }

  /// Declares all not disposed objects as leaks, even if they are not GCed yet.
  ///
  /// Is used to make sure all disposables are disposed
  /// by the the end of the test.
  void declareAllNotDisposedAsLeaks() {
    throwIfDisposed();
    // We need this temporary storage to avoid error
    // 'concurrent modification during iteration'
    // for internal iterables in `_objects.notGCed`.
    final notGCedAndNotDisposed = <ObjectRecord>[];
    _objects.notGCed.toIterable().forEach((record) {
      if (!record.isDisposed) notGCedAndNotDisposed.add(record);
    });
    notGCedAndNotDisposed.forEach(_declareNotDisposedLeak);
  }

  void dispatchDisposal(
    Object object, {
    required Map<String, dynamic>? context,
  }) {
    throwIfDisposed();

    final record = _objects.notGCed.record(object);
    // If object is not registered, this may mean that
    // it was created when leak tracking was off.
    if (record == null || record.phase.ignoreLeaks) return;

    record.mergeContext(context);

    if (record.phase.leakDiagnosticConfig.collectStackTraceOnDisposal) {
      record.setContext(ContextKeys.disposalCallstack, StackTrace.current);
    }

    _objects.assertRecordIntegrity(record);

    record.setDisposed(_gcCounter.gcCount, clock.now());
    _objects.notGCedDisposedOk.add(record);

    _objects.assertRecordIntegrity(record);
  }

  void addContext(Object object, {required Map<String, dynamic>? context}) {
    throwIfDisposed();

    final record = _objects.notGCed.record(object);
    // If object is not registered, this may mean that
    // it was created when leak tracking was off.
    if (record == null || record.phase.ignoreLeaks) return;

    record.mergeContext(context);
  }

  @override
  Future<LeakSummary> leaksSummary() async {
    throwIfDisposed();
    await _checkForNewNotGCedLeaks(summary: true);

    return LeakSummary({
      LeakType.notDisposed: _objects.gcedNotDisposedLeaks.length,
      LeakType.notGCed: _objects.notGCedDisposedLate.length,
      LeakType.gcedLate: _objects.gcedLateLeaks.length,
    });
  }

  Future<void> _checkForNewNotGCedLeaks({bool summary = false}) async {
    _objects.assertIntegrity();

    final objectsToGetPath = summary ? null : <ObjectRecord>[];

    final now = clock.now();
    for (final record in _objects.notGCedDisposedOk.toList(growable: false)) {
      if (record.isNotGCedLeak(
        _gcCounter.gcCount,
        now,
        disposalTime,
        numberOfGcCycles,
      )) {
        _objects.notGCedDisposedOk.remove(record);
        _objects.notGCedDisposedLate.add(record);
        if (record.phase.leakDiagnosticConfig.collectRetainingPathForNotGCed) {
          objectsToGetPath?.add(record);
        }
      }
    }

    await processIfNeeded(
      items: objectsToGetPath,
      limit: maxRequestsForRetainingPath,
      processor: _addRetainingPath,
    );

    _objects.assertIntegrity();
  }

  /// Runs [processor] for first items from [items],
  /// at most [limit] items will be processed.
  ///
  /// Noop if [items] is null or empty.
  /// Processes all items if [limit] is null.
  @visibleForTesting
  static Future<void> processIfNeeded<T>({
    required List<T>? items,
    required int? limit,
    required Future<void> Function(List<T>) processor,
  }) async {
    if (items == null || items.isEmpty) return;

    if (limit != null) {
      items = items.sublist(
        0,
        min(limit, items.length),
      );
    }
    await processor(items);
  }

  Future<void> _addRetainingPath(List<ObjectRecord> objectsToGetPath) async {
    final connection = await connect();

    final pathSetters = objectsToGetPath.map((record) async {
      final path = await retainingPath(connection, record.ref.target);
      if (path != null) {
        record.setContext(ContextKeys.retainingPath, path);
      }
    });

    await Future.wait(
      pathSetters,
      eagerError: true,
    );
  }

  @override
  Future<void> checkNotGCed() async {
    throwIfDisposed();
    await _checkForNewNotGCedLeaks();
  }

  @override
  Future<Leaks> collectLeaks() async {
    throwIfDisposed();

    await _checkForNewNotGCedLeaks();

    final result = Leaks({
      LeakType.notDisposed: _objects.gcedNotDisposedLeaks
          .where(
            (record) => _leakFilter.shouldReport(LeakType.notDisposed, record),
          )
          .map((record) => record.toLeakReport())
          .toList(),
      LeakType.notGCed: _objects.notGCedDisposedLate
          .where(
            (record) => _leakFilter.shouldReport(
              LeakType.notGCed,
              record,
            ),
          )
          .map((record) => record.toLeakReport())
          .toList(),
      LeakType.gcedLate: _objects.gcedLateLeaks
          .where((record) => _leakFilter.shouldReport(LeakType.notGCed, record))
          .map((record) => record.toLeakReport())
          .toList(),
    });

    _objects.notGCedDisposedLateCollected.addAll(_objects.notGCedDisposedLate);
    _objects.notGCedDisposedLate.clear();
    _objects.gcedNotDisposedLeaks.clear();
    _objects.gcedLateLeaks.clear();

    return result;
  }

  void throwIfDisposed() {
    if (disposed) throw StateError('The disposed instance should not be used.');
  }

  void dispose() {
    throwIfDisposed();
    disposed = true;
  }

  int get notGCed => _objects.notGCed.length;

  Iterable<ObjectRecord> tracked() => _objects.notGCed.toIterable();
}
