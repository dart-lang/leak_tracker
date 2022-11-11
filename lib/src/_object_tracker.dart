// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_gc_counter.dart';
import '_object_record.dart';
import '_primitives.dart';
import 'leak_tracker_model.dart';

class ObjectTracker {
  /// The parameters are injected for testing purposes.
  ObjectTracker(
    this._config, {
    FinalizerBuilder? finalizerBuilder,
    GcCounter? gcCounter,
  }) {
    finalizerBuilder ??= buildFinalizer;
    _finalizer = finalizerBuilder(_objectGarbageCollected);
    _gcCounter = gcCounter ?? GcCounter();
  }

  late Finalizer<Object> _finalizer;
  late GcCounter _gcCounter;
  final _objects = ObjectRecords();
  final LeakTrackingConfiguration _config;

  void _objectGarbageCollected(Object code) {
    if (code is! int) throw 'Object token should be integer.';

    if (_objects.duplicates.contains(code)) return;

    final ObjectRecord? record = _objects.notGCed[code];
    if (record == null) {
      throw '$code should not be garbage collected twice.';
    }
    _objects.assertRecordIntegrity(code);

    record.setGCed(_gcCounter.gcCount, DateTime.now());

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

  void startTracking(Object object, Map<String, dynamic>? context) {
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
      record.addDetails()
      info.details.add(StackTrace.current.toString());
    }

    _notGCed[code] = info;
    _notGCedFresh.add(code);
    assert(_assertIntegrity(info));
  }

  /// Normally one ContainerLayer is created  in a Flutter app before main() is invoked.
  /// So, it is not registered, but disposed.
  /// This flag makes sure there is just one such object.
  int? oneNotRegisteredContainerLayer;

  bool _checkForNotRegisteredContainer(Object object, int code) {
    if (_notGCed.containsKey(code)) return false;
    assert(object.runtimeType.toString().contains('Layer'));
    assert(
      oneNotRegisteredContainerLayer == null ||
          oneNotRegisteredContainerLayer == code,
    );
    oneNotRegisteredContainerLayer = code;
    return true;
  }

  void registerDisposal(Object object, String? details) {
    final code = identityHashCode(object);
    if (_duplicates.contains(code)) return;
    if (_checkForNotRegisteredContainer(object, code)) return;
    final TrackedObjectInfo info = _notGCed[code]!;
    if (details != null) info.details.add(details);
    assert(_assertIntegrity(info));

    info.setDisposed(_gcTime.now);

    assert(_assertIntegrity(info));
  }

  void addDetails(Object object, String details) {
    final code = identityHashCode(object);
    if (_duplicates.contains(code)) {
      throw 'The object is has duplicate hash code.';
      return;
    }
    if (_checkForNotRegisteredContainer(object, code)) return;
    if (!_notGCed.containsKey(code))
      throw 'The object is not registered for tracking.';
    _notGCed[code]!.details.add(details);
  }

  LeakSummary collectLeaksSummary() {
    _checkForNewNotGCedLeaks();

    return LeakSummary({
      LeakType.notDisposed: _gcedNotDisposedLeaks.length,
      LeakType.notGCed: _notGCedLate.length,
      LeakType.gcedLate: _gcedLateLeaks.length,
    });
  }

  void _checkForNewNotGCedLeaks() {
    assert(_assertIntegrityForAll());
    for (int code in _notGCedFresh.toList(growable: false)) {
      final TrackedObjectInfo info = _notGCed[code]!;
      if (info.isNotGCedLeak(_gcTime.now)) {
        _notGCedFresh.remove(code);
        _notGCedLate.add(code);
      }
    }

    _assertIntegrityForAll();
  }

  Leaks collectLeaks() {
    _checkForNewNotGCedLeaks();

    return Leaks({
      LeakType.notDisposed: _gcedNotDisposedLeaks
          .map((TrackedObjectInfo i) => i.toLeakReport())
          .toList(),
      LeakType.notGCed:
          _notGCedLate.map((t) => _notGCed[t]!.toLeakReport()).toList(),
      LeakType.gcedLate: _gcedLateLeaks
          .map((TrackedObjectInfo i) => i.toLeakReport())
          .toList(),
    });
  }

  /// Normally there is no duplicates or 1-2 per application run. If there are
  /// more, this means an error.
  final _maxAllowedDuplicates = 100;
  bool _checkForDuplicate(int code) {
    if (!_notGCed.containsKey(code)) return false;
    if (_duplicates.contains(code)) return true;
    _duplicates.add(code);
    _notGCed.remove(code);
    _notGCedLate.remove(code);
    _notGCedFresh.remove(code);
    if (_duplicates.length > _maxAllowedDuplicates) throw 'Too many duplicates';
    return true;
  }
}
