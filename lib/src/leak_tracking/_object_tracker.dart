// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';

import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_gc_counter.dart';
import '_object_record.dart';
import 'leak_tracker_model.dart';
import 'retaining_path/retaining_path.dart';

/// Keeps collection of object records until
/// disposal and garbage gollection.
///
/// If disposal and garbage collection happened abnormally,
/// marks the object as leaked.
class ObjectTracker implements LeakProvider {
  /// The optional parameters are injected for testing purposes.
  ObjectTracker({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    required this.disposalTimeBuffer,
    FinalizerBuilder? finalizerBuilder,
    GcCounter? gcCounter,
    IdentityHashCoder? coder,
  }) {
    _coder = coder ?? standardIdentityHashCoder;
    finalizerBuilder ??= buildStandardFinalizer;
    _finalizer = finalizerBuilder(_onOobjectGarbageCollected);
    _gcCounter = gcCounter ?? GcCounter();
  }

  late IdentityHashCoder _coder;

  /// Time to allow the disposal invoker to release the reference to the object.
  final Duration disposalTimeBuffer;

  late Finalizer<Object> _finalizer;

  late GcCounter _gcCounter;

  final _objects = ObjectRecords();

  bool disposed = false;

  final LeakDiagnosticConfig leakDiagnosticConfig;

  void startTracking(
    Object object, {
    required Map<String, dynamic>? context,
    required String trackedClass,
  }) {
    throwIfDisposed();
    final code = _coder(object);
    if (_checkForDuplicate(code)) return;

    _finalizer.attach(object, code);

    final record = ObjectRecord(
      _coder(object),
      context,
      object.runtimeType,
      trackedClass,
    );

    if (leakDiagnosticConfig
        .shouldCollectStackTraceOnStart(object.runtimeType.toString())) {
      record.setContext(ContextKeys.startCallstack, StackTrace.current);
    }

    _objects.notGCed[code] = record;

    _objects.assertRecordIntegrity(code);
  }

  void _onOobjectGarbageCollected(Object code) {
    if (disposed) return;
    if (code is! int) throw 'Object token should be integer.';

    if (_objects.duplicates.contains(code)) return;

    _objects.assertRecordIntegrity(code);
    final record = _notGCed(code);
    record.setGCed(_gcCounter.gcCount, clock.now());

    if (record.isGCedLateLeak(disposalTimeBuffer)) {
      _objects.gcedLateLeaks.add(record);
    } else if (record.isNotDisposedLeak) {
      _objects.gcedNotDisposedLeaks.add(record);
    }

    _objects.notGCed.remove(code);
    _objects.notGCedDisposedOk.remove(code);
    _objects.notGCedDisposedLate.remove(code);
    _objects.notGCedDisposedLateCollected.remove(code);

    _objects.assertRecordIntegrity(code);
  }

  /// Number of times [dispatchDisposal] or [addContext] were invoked for
  /// not registered objects.
  ///
  /// Normally one ContainerLayer is created in a Flutter app before main() is invoked.
  /// The layer and it's children are not registered, but disposed.
  int _notRegisterdObjects = 0;

  final _maxAllowedNotRegisterdObjects = 100;

  bool _checkForNotRegisteredObject(Object object, int code) {
    if (_objects.notGCed.containsKey(code)) return false;
    _notRegisterdObjects++;

    assert(_notRegisterdObjects <= _maxAllowedNotRegisterdObjects);
    return true;
  }

  void dispatchDisposal(
    Object object, {
    required Map<String, dynamic>? context,
  }) {
    throwIfDisposed();
    final code = _coder(object);
    if (_objects.duplicates.contains(code)) return;
    if (_checkForNotRegisteredObject(object, code)) return;

    final record = _notGCed(code);
    record.mergeContext(context);

    if (leakDiagnosticConfig
        .shouldCollectStackTraceOnDisposal(object.runtimeType.toString())) {
      record.setContext(ContextKeys.disposalCallstack, StackTrace.current);
    }

    _objects.assertRecordIntegrity(code);

    record.setDisposed(_gcCounter.gcCount, clock.now());
    _objects.notGCedDisposedOk.add(code);

    _objects.assertRecordIntegrity(code);
  }

  void addContext(Object object, {required Map<String, dynamic>? context}) {
    throwIfDisposed();
    final code = _coder(object);
    if (_objects.duplicates.contains(code)) return;
    if (_checkForNotRegisteredObject(object, code)) return;
    final record = _notGCed(code);
    record.mergeContext(context);
  }

  @override
  Future<LeakSummary> leaksSummary() async {
    throwIfDisposed();
    await _checkForNewNotGCedLeaks();

    return LeakSummary({
      LeakType.notDisposed: _objects.gcedNotDisposedLeaks.length,
      LeakType.notGCed: _objects.notGCedDisposedLate.length,
      LeakType.gcedLate: _objects.gcedLateLeaks.length,
    });
  }

  Future<void> _checkForNewNotGCedLeaks() async {
    _objects.assertIntegrity();

    final List<int>? objectsToGetPath =
        leakDiagnosticConfig.collectRetainingPathForNonGCed ? [] : null;

    final now = clock.now();
    for (int code in _objects.notGCedDisposedOk.toList(growable: false)) {
      if (_notGCed(code)
          .isNotGCedLeak(_gcCounter.gcCount, now, disposalTimeBuffer)) {
        _objects.notGCedDisposedOk.remove(code);
        _objects.notGCedDisposedLate.add(code);
        objectsToGetPath?.add(code);
      }
    }

    await _maybeAddRetainingPath(objectsToGetPath);

    _objects.assertIntegrity();
  }

  Future<void> _maybeAddRetainingPath(List<int>? objectsToGetPath) async {
    if (objectsToGetPath == null) return;

    final pathObtainers = objectsToGetPath.map((code) async {
      final record = _objects.notGCed[code]!;
      record.setContext(
        ContextKeys.retainingPath,
        await obtainRetainingPath(record.type, record.code),
      );
    });
    await Future.wait(pathObtainers);
  }

  ObjectRecord _notGCed(int code) {
    final result = _objects.notGCed[code];
    if (result == null) {
      throw 'The object with code $code is not registered for tracking.';
    }
    return result;
  }

  @override
  Future<Leaks> collectLeaks() async {
    throwIfDisposed();
    await _checkForNewNotGCedLeaks();

    final result = Leaks({
      LeakType.notDisposed: _objects.gcedNotDisposedLeaks
          .map((record) => record.toLeakReport())
          .toList(),
      LeakType.notGCed: _objects.notGCedDisposedLate
          .map((code) => _notGCed(code).toLeakReport())
          .toList(),
      LeakType.gcedLate: _objects.gcedLateLeaks
          .map((record) => record.toLeakReport())
          .toList(),
    });

    _objects.notGCedDisposedLateCollected.addAll(_objects.notGCedDisposedLate);
    _objects.notGCedDisposedLate.clear();
    _objects.gcedNotDisposedLeaks.clear();
    _objects.gcedLateLeaks.clear();

    return result;
  }

  final _maxAllowedDuplicates = 100;

  /// Normally there is no duplicates or 1-2 per application run. If there are
  /// more, this means an error.
  bool _checkForDuplicate(int code) {
    if (!_objects.notGCed.containsKey(code)) return false;
    if (_objects.duplicates.contains(code)) return true;

    _objects.duplicates.add(code);
    _objects.notGCed.remove(code);
    _objects.notGCedDisposedOk.remove(code);
    _objects.notGCedDisposedLate.remove(code);
    _objects.notGCedDisposedLateCollected.remove(code);

    if (_objects.duplicates.length > _maxAllowedDuplicates) {
      throw 'Too many duplicates, Please, file a bug '
          'to https://github.com/dart-lang/leak_tracker/issues.';
    }

    return true;
  }

  void throwIfDisposed() {
    if (disposed) throw StateError('The disposed instance should not be used.');
  }

  void dispose() {
    throwIfDisposed();
    disposed = true;
  }

  int get notGCed => _objects.notGCed.length;
}
