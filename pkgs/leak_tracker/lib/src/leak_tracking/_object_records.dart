// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_object_record.dart';
import '_object_record_set.dart';

/// Object collections to track leaks.
///
/// Objects migrate between collections based on their state.
///
/// On registration, each object enters the collections [notGCed].
/// On disposal it is added to [notGCedDisposedOk]. Then, if it is overdue
/// to be GCed it migrates from to [notGCedDisposedLate].
/// Then, if the leak is collected, it
/// migrates to [notGCedDisposedLateCollected].
///
/// If the object gets GCed, it is removed from all notGCed... collections,
/// and, if it was GCed wrongly, added to one of gced... collections.
class ObjectRecords {
  /// All not GCed objects.
  final notGCed = ObjectRecordSet();

  /// Not GCed objects, that were disposed and are not expected to be GCed yet.
  final notGCedDisposedOk = <ObjectRecord>{};

  /// Not GCed objects, that were disposed and are overdue to be GCed.
  final notGCedDisposedLate = <ObjectRecord>{};

  /// Not GCed objects, that were disposed, are overdue to be GCed,
  /// and were collected as nonGCed leaks.
  final notGCedDisposedLateCollected = <ObjectRecord>{};

  /// GCed objects that were late to be GCed.
  final List<ObjectRecord> gcedLateLeaks = <ObjectRecord>[];

  /// GCed objects that were not disposed.
  final List<ObjectRecord> gcedNotDisposedLeaks = <ObjectRecord>[];

  void _assertNotWatchedToBeGCed(ObjectRecord record) {
    assert(() {
      assert(!notGCed.contains(record));
      assert(!notGCedDisposedOk.contains(record));
      assert(!notGCedDisposedLate.contains(record));
      assert(!notGCedDisposedLateCollected.contains(record));
      return true;
    }());
  }

  void assertRecordIntegrity(ObjectRecord record) {
    assert(() {
      final notGCedSetMembership =
          (notGCedDisposedOk.contains(record) ? 1 : 0) +
              (notGCedDisposedLate.contains(record) ? 1 : 0) +
              (notGCedDisposedLateCollected.contains(record) ? 1 : 0);

      assert(notGCedSetMembership <= 1);

      if (notGCedSetMembership == 1) {
        assert(notGCed.contains(record));
      }

      return true;
    }());
  }

  void assertIntegrity() {
    assert(() {
      notGCed.toIterable().forEach(assertRecordIntegrity);
      gcedLateLeaks.forEach(_assertNotWatchedToBeGCed);
      gcedNotDisposedLeaks.forEach(_assertNotWatchedToBeGCed);
      return true;
    }());
  }
}
