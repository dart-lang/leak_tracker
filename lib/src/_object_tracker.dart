// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';

import '_gc_counter.dart';
import '_model.dart';
import '_object_record.dart';
import '_primitives.dart';
import 'devtools_integration/model.dart';

class ObjectTracker implements LeakProvider {
  /// The optional parameters are injected for testing purposes.
  ObjectTracker({
    this.classesToCollectStackTraceOnStart = const {},
    this.classesToCollectStackTraceOnDisposal = const {},
    FinalizerBuilder? finalizerBuilder,
    GcCounter? gcCounter,
  }) {
    finalizerBuilder ??= buildFinalizer;
    _finalizer = finalizerBuilder(_onOobjectGarbageCollected);
    _gcCounter = gcCounter ?? GcCounter();
  }

  late Finalizer<Object> _finalizer;
  late GcCounter _gcCounter;
  final _objects = ObjectRecords();
  bool disposed = false;

  /// We use String, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnStart;

  /// We use String, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnDisposal;

  void startTracking(
    Object object, {
    required Map<String, dynamic>? context,
    required String trackedClass,
  }) {
    throwIfDisposed();
    final code = identityHashCode(object);
    if (_checkForDuplicate(code)) return;

    _finalizer.attach(object, code);

    final record = ObjectRecord(
      identityHashCode(object),
      context,
      object.runtimeType,
      trackedClass,
    );

    if (classesToCollectStackTraceOnStart
        .contains(object.runtimeType.toString())) {
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

    if (record.isGCedLateLeak) {
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

  /// Normally one ContainerLayer is created  in a Flutter app before main() is invoked.
  /// So, it is not registered, but disposed.
  /// This flag makes sure there is just one such object.
  int? _oneNotRegisteredContainerLayer;

  bool _checkForNotRegisteredContainer(Object object, int code) {
    if (_objects.notGCed.containsKey(code)) return false;
    assert(object.runtimeType.toString().contains('Layer'));
    assert(
      _oneNotRegisteredContainerLayer == null ||
          _oneNotRegisteredContainerLayer == code,
    );
    _oneNotRegisteredContainerLayer = code;
    return true;
  }

  void dispatchDisposal(
    Object object, {
    required Map<String, dynamic>? context,
  }) {
    throwIfDisposed();
    final code = identityHashCode(object);
    if (_objects.duplicates.contains(code)) return;
    if (_checkForNotRegisteredContainer(object, code)) return;

    final record = _notGCed(code);
    record.mergeContext(context);
    if (classesToCollectStackTraceOnDisposal
        .contains(object.runtimeType.toString())) {
      record.setContext(ContextKeys.disposalCallstack, StackTrace.current);
    }

    _objects.assertRecordIntegrity(code);

    record.setDisposed(_gcCounter.gcCount, clock.now());
    _objects.notGCedDisposedOk.add(code);

    _objects.assertRecordIntegrity(code);
  }

  void addContext(Object object, {required Map<String, dynamic>? context}) {
    throwIfDisposed();
    final code = identityHashCode(object);
    if (_objects.duplicates.contains(code)) return;
    if (_checkForNotRegisteredContainer(object, code)) return;
    final record = _notGCed(code);
    record.mergeContext(context);
  }

  @override
  LeakSummary leaksSummary() {
    throwIfDisposed();
    _checkForNewNotGCedLeaks();

    return LeakSummary({
      LeakType.notDisposed: _objects.gcedNotDisposedLeaks.length,
      LeakType.notGCed: _objects.notGCedDisposedLate.length,
      LeakType.gcedLate: _objects.gcedLateLeaks.length,
    });
  }

  void _checkForNewNotGCedLeaks() {
    _objects.assertIntegrity();

    final now = clock.now();
    for (int code in _objects.notGCedDisposedOk.toList(growable: false)) {
      if (_notGCed(code).isNotGCedLeak(_gcCounter.gcCount, now)) {
        _objects.notGCedDisposedOk.remove(code);
        _objects.notGCedDisposedLate.add(code);
      }
    }

    _objects.assertIntegrity();
  }

  ObjectRecord _notGCed(int code) {
    final result = _objects.notGCed[code];
    if (result == null)
      throw 'The object with code $code is not registered for tracking.';
    return result;
  }

  @override
  Leaks collectLeaks() {
    throwIfDisposed();
    _checkForNewNotGCedLeaks();

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
    _finalizer.detach(code);
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
}
