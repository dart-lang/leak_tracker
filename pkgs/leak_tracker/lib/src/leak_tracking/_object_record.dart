// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_primitives/_gc_counter.dart';
import '_primitives/model.dart';

@visibleForTesting
class ObjectRecordSet {
  final records = <IdentityHashCode, List<ObjectRecord>>{};

  ObjectRecord? record(Object object) {
    final code = identityHashCode(object);

    final list = records[code];
    if (list == null) return null;
    return list.firstWhereOrNull((r) => r.ref.target == object);
  }

  ObjectRecord addOrGet(Object object) {
    final code = identityHashCode(object);

    final list = records[code];
    if (list != null) {
      final result = list.firstWhereOrNull((r) => r.ref.target == object);
      if (result != null) return result;
    }

    return null;
    return list.firstWhereOrNull((r) => r.ref.target == object);
  }
}

/// Object collections to track leaks.
///
/// Objects migrate between collections based on their state.
///
/// On registration, each object enters the collections [notGCed].
/// On disposal it is added to [notGCedDisposedOk]. Then, if it is overdue
/// to be GCed it migrates from to [notGCedDisposedLate].
/// Then, if the leak is collected, it migrates to [notGCedDisposedLateCollected].
///
/// If the object gets GCed, it is removed from all notGCed... collections,
/// and, if it was GCed wrongly, added to one of gced... collections.
class ObjectRecords {
  /// All not GCed objects.
  final Map<IdentityHashCode, ObjectRecord> notGCed =
      <IdentityHashCode, ObjectRecord>{};

  /// Not GCed objects, that were disposed and are not expected to be GCed yet.
  final Set<IdentityHashCode> notGCedDisposedOk = <IdentityHashCode>{};

  /// Not GCed objects, that were disposed and are overdue to be GCed.
  final Set<IdentityHashCode> notGCedDisposedLate = <IdentityHashCode>{};

  /// Not GCed objects, that were disposed, are overdue to be GCed,
  /// and were collected as nonGCed leaks.
  final Set<IdentityHashCode> notGCedDisposedLateCollected =
      <IdentityHashCode>{};

  /// GCed objects that were late to be GCed.
  final List<ObjectRecord> gcedLateLeaks = <ObjectRecord>[];

  /// GCed ibjects that were not disposed.
  final List<ObjectRecord> gcedNotDisposedLeaks = <ObjectRecord>[];

  /// As identityHashCode is not unique, we ignore objects that happen to have
  /// equal code.
  final Set<IdentityHashCode> duplicates = <int>{};

  void _assertNotWatched(IdentityHashCode code) {
    assert(() {
      assert(!notGCed.containsKey(code));
      assert(!notGCedDisposedOk.contains(code));
      assert(!notGCedDisposedLate.contains(code));
      assert(!notGCedDisposedLateCollected.contains(code));
      return true;
    }());
  }

  void assertRecordIntegrity(IdentityHashCode code) {
    assert(() {
      final notGCedSetMembership = (notGCedDisposedOk.contains(code) ? 1 : 0) +
          (notGCedDisposedLate.contains(code) ? 1 : 0) +
          (notGCedDisposedLateCollected.contains(code) ? 1 : 0);

      assert(notGCedSetMembership <= 1);

      if (notGCedSetMembership == 1) {
        assert(notGCed.containsKey(code));
      }

      if (duplicates.contains(code)) _assertNotWatched(code);
      return true;
    }());
  }

  void assertIntegrity() {
    assert(() {
      notGCed.keys.forEach(assertRecordIntegrity);
      gcedLateLeaks.map((e) => e.code).forEach(_assertNotWatched);
      gcedNotDisposedLeaks.map((e) => e.code).forEach(_assertNotWatched);
      duplicates.forEach(_assertNotWatched);
      return true;
    }());
  }
}

/// Information about an object, tracked for leaks.
class ObjectRecord {
  ObjectRecord(
    Object object,
    this.context,
    this.type,
    this.trackedClass,
    this.phase,
  )   : code = identityHashCode(object),
        ref = WeakReference(object);

  final WeakReference<Object> ref;

  final IdentityHashCode code;

  Map<String, dynamic>? context;

  final PhaseSettings phase;

  /// Type of the tracked object.
  final Type type;

  final String trackedClass;

  DateTime? _disposalTime;
  int? _disposalGcCount;

  void setDisposed(int gcTime, DateTime time) {
    // TODO(polina-c): handle double disposal in a better way
    // https://github.com/dart-lang/leak_tracker/issues/118
    // Noop if object is already disposed.
    if (_disposalGcCount != null) return;
    if (_gcedGcCount != null) {
      throw 'The object $code should not be disposed after being GCed.';
    }
    _disposalGcCount = gcTime;
    _disposalTime = time;
  }

  DateTime? _gcedTime;
  int? _gcedGcCount;
  void setGCed(int gcCount, DateTime time) {
    if (_gcedGcCount != null) throw 'The object $code GCed twice.';
    _gcedGcCount = gcCount;
    _gcedTime = time;
  }

  bool get isGCed => _gcedGcCount != null;
  bool get isDisposed => _disposalGcCount != null;

  bool isGCedLateLeak(Duration disposalTime, int numberOfGcCycles) {
    if (_disposalGcCount == null || _gcedGcCount == null) return false;
    assert(_gcedTime != null);
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: _gcedGcCount!,
      currentTime: _gcedTime!,
      disposalTime: disposalTime,
      numberOfGcCycles: numberOfGcCycles,
    );
  }

  bool isNotGCedLeak(
    int currentGcCount,
    DateTime currentTime,
    Duration disposalTime,
    int numberOfGcCycles,
  ) {
    if (_gcedGcCount != null) return false;
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: currentGcCount,
      currentTime: currentTime,
      disposalTime: disposalTime,
      numberOfGcCycles: numberOfGcCycles,
    );
  }

  bool get isNotDisposedLeak {
    return isGCed && !isDisposed;
  }

  void setContext(String key, Object value) {
    final theContext = context ?? {};
    theContext[key] = value;
    context = theContext;
  }

  void mergeContext(Map<String, dynamic>? addedContext) {
    if (addedContext == null) return;
    final theContext = context;
    if (theContext == null) {
      context = addedContext;
      return;
    }
    theContext.addAll(addedContext);
  }

  LeakReport toLeakReport() => LeakReport(
        type: type.toString(),
        context: context,
        code: code,
        trackedClass: trackedClass,
        phase: phase.name,
      );
}
