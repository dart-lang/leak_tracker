// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';

import '_gc_counter.dart';
import '_object_record.dart';
import '_primitives.dart';
import 'leak_analysis_model.dart';
import 'leak_tracker_model.dart';

class ObjectTracker {
  /// The optional parameters are injected for testing purposes.
  ObjectTracker(
    this._config, {
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
  final LeakTrackingConfiguration _config;

  void startTracking(Object object, {required Map<String, dynamic>? context}) {
    final code = identityHashCode(object);
    if (_checkForDuplicate(code)) return;

    _finalizer.attach(object, code);

    final record = ObjectRecord(
      identityHashCode(object),
      context,
      object.runtimeType,
    );

    if (_config.classesToCollectStackTraceOnTrackingStart
        .contains(object.runtimeType.toString())) {
      record.setContext(ContextKeys.startCallstack, StackTrace.current);
    }

    _objects.notGCed[code] = record;

    _objects.assertRecordIntegrity(code);
  }

  void _onOobjectGarbageCollected(Object code) {
    if (code is! int) throw 'Object token should be integer.';

    if (_objects.duplicates.contains(code)) return;

    final ObjectRecord? record = _objects.notGCed[code];
    if (record == null) {
      throw '$code should not be garbage collected twice.';
    }
    _objects.assertRecordIntegrity(code);

    record.setGCed(_gcCounter.gcCount, clock.now());

    if (record.isGCedLateLeak) {
      _objects.gcedLateLeaks.add(record);
    } else if (record.isNotDisposedLeak) {
      _objects.gcedNotDisposedLeaks.add(record);
    }

    _objects.notGCed.remove(code);
    _objects.notGCedDisposedOk.remove(code);
    _objects.notGCedDisposedLate.remove(code);

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

  void registerDisposal(
    Object object, {
    required Map<String, dynamic>? context,
  }) {
    final code = identityHashCode(object);
    if (_objects.duplicates.contains(code)) return;
    if (_checkForNotRegisteredContainer(object, code)) return;

    final record = _objects.notGCed[code]!;
    record.mergeContext(context);

    _objects.assertRecordIntegrity(code);

    record.setDisposed(_gcCounter.gcCount, clock.now());
    _objects.notGCedDisposedOk.add(code);

    _objects.assertRecordIntegrity(code);
  }

  void addContext(Object object, {required Map<String, dynamic>? context}) {
    final code = identityHashCode(object);
    if (_objects.duplicates.contains(code)) return;
    if (_checkForNotRegisteredContainer(object, code)) return;
    final record = _objects.notGCed[code];
    if (record == null) throw 'The object is not registered for tracking.';
    record.mergeContext(context);
  }

  LeakSummary collectLeaksSummary() {
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
      final record = _objects.notGCed[code]!;
      if (record.isNotGCedLeak(_gcCounter.gcCount, now)) {
        _objects.notGCedDisposedOk.remove(code);
        _objects.notGCedDisposedLate.add(code);
      }
    }

    _objects.assertIntegrity();
  }

  Leaks collectLeaks() {
    _checkForNewNotGCedLeaks();

    return Leaks({
      LeakType.notDisposed: _objects.gcedNotDisposedLeaks
          .map((record) => record.toLeakReport())
          .toList(),
      LeakType.notGCed: _objects.notGCedDisposedLate
          .map((code) => _objects.notGCed[code]!.toLeakReport())
          .toList(),
      LeakType.gcedLate: _objects.gcedLateLeaks
          .map((record) => record.toLeakReport())
          .toList(),
    });
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
    if (_objects.duplicates.length > _maxAllowedDuplicates) {
      throw 'Too many duplicates, Please, file a bug '
          'to https://github.com/dart-lang/leak_tracker/issues.';
    }
    return true;
  }
}
