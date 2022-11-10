// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_gc_counter.dart';
import '_primitives.dart';

class ObjectTracker {
  /// The parameters are injected for testing purposes.
  ObjectTracker({
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

  void _objectGarbageCollected(Object code) {
    if (code is! int) throw 'Object token should be integer.';
    if (_duplicates.contains(code)) return;
    final TrackedObjectInfo? info = _notGCed[code];
    if (info == null) {
      throw '$code cannot be garbage collected twice.';
    }
    assert(_assertIntegrity(info));
    info.setGCed(_gcTime.now);

    if (info.isGCedLateLeak) {
      _gcedLateLeaks.add(info);
    } else if (info.isNotDisposedLeak) {
      _gcedNotDisposedLeaks.add(info);
    }
    _notGCed.remove(code);
    _notGCedFresh.remove(code);
    _notGCedLate.remove(code);

    assert(_assertIntegrity(info));
  }

  void startTracking(Object object, String? details) {
    final code = identityHashCode(object);
    if (_checkForDuplicate(code)) return;

    _finalizer.attach(object, code);

    final TrackedObjectInfo info = TrackedObjectInfo(
      object,
      <String>[
        if (details != null) details,
      ],
    );

    final config = leakTrackingConfiguration!;
    if (config.classesToCollectStackTraceOnTrackingStart
        .contains(object.runtimeType.toString())) {
      info.details.add(StackTrace.current.toString());
    }

    _notGCed[code] = info;
    _notGCedFresh.add(code);
    assert(_assertIntegrity(info));
  }

  /// Normally one ContainerLayer is created before main() is invoked.
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

  bool _assertIntegrity(TrackedObjectInfo info) {
    if (_notGCed.containsKey(info.code)) {
      assert(_notGCed[info.code]!.code == info.code);

      // It was false one time.
      assert(!info.isGCed);
    }

    assert(
      _gcedLateLeaks.contains(info) == info.isGCedLateLeak,
      '${_gcedLateLeaks.contains(info)}, ${info.isDisposed}, ${info.isGCed},',
    );

    assert(
      _gcedNotDisposedLeaks.contains(info) == (info.isGCed && !info.isDisposed),
      '${_gcedNotDisposedLeaks.contains(info)}, ${info.isGCed}, ${!info.isDisposed}',
    );

    return true;
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

  bool _assertIntegrityForAll() {
    _assertIntegrityForCollections();
    _notGCed.values.forEach(_assertIntegrity);
    _gcedLateLeaks.forEach(_assertIntegrity);
    _gcedNotDisposedLeaks.forEach(_assertIntegrity);
    return true;
  }

  bool _assertIntegrityForCollections() {
    assert(_notGCed.length == _notGCedFresh.length + _notGCedLate.length);
    return true;
  }

  void registerOldGCEvent() {
    _gcTime.registerOldGCEvent();
  }

  /// Normally there is no duplicates or 1-2 per application run. If there are
  /// more, this means there is an issue.
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
