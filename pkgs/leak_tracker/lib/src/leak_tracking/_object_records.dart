// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import '../shared/_primitives.dart';
import '_object_record.dart';
import '_primitives/model.dart';

@visibleForTesting
class ObjectRecordSet {
  ObjectRecordSet({this.coder = standardIdentityHashCoder});

  final IdentityHashCoder coder;

  final _records = <IdentityHashCode, List<ObjectRecord>>{};

  ObjectRecord? record(Object object) {
    final code = identityHashCode(object);

    final list = _records[code];
    if (list == null) return null;

    return list.firstWhereOrNull((r) => r.ref.target == object);
  }

  void remove(ObjectRecord record) {
    final list = _records[record.code];
    list?.removeWhere((r) => r == record);
    if (list == null || list.isEmpty) _records.remove(record.code);
  }

  ObjectRecord putIfAbsent(
    Object object,
    Map<String, dynamic>? context,
    PhaseSettings phase,
    String trackedClass,
  ) {
    final code = identityHashCode(object);

    final list = _records.putIfAbsent(code, () => []);

    final existing = list.firstWhereOrNull((r) => r.ref.target == object);
    if (existing != null) return existing;

    final result = ObjectRecord(object, context, trackedClass, phase);
    list.add(result);
    return result;
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
