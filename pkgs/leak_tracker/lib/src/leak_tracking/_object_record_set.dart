// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../shared/_primitives.dart';
import '_object_record.dart';
import 'primitives/_test_helper_detector.dart';
import 'primitives/model.dart';

@visibleForTesting
class ObjectRecordSet {
  ObjectRecordSet({@visibleForTesting this.coder = standardIdentityHashCoder});

  final IdentityHashCoder coder;

  final _records = <IdentityHashCode, List<ObjectRecord>>{};

  bool contains(ObjectRecord record) {
    final list = _records[record.code];
    if (list == null) return false;
    return list.contains(record);
  }

  ObjectRecord? record(Object object) {
    final code = identityHashCode(object);

    final list = _records[code];
    if (list == null) return null;

    return list.firstWhereOrNull((r) => r.ref.target == object);
  }

  /// Removes record if it exists in the set.
  void remove(ObjectRecord record) {
    final list = _records[record.code];
    if (list == null) return;
    var removed = false;
    list.removeWhere((r) {
      if (r == record) {
        assert(!removed);
        removed = true;
      }
      return r == record;
    });
    _length--;
    if (list.isEmpty) _records.remove(record.code);
  }

  ({ObjectRecord record, bool wasAbsent}) putIfAbsent(
    Object object,
    Map<String, dynamic>? context,
    PhaseSettings phase,
    String trackedClass,
  ) {
    final code = identityHashCode(object);

    final list = _records.putIfAbsent(code, () => []);

    final existing =
        list.firstWhereOrNull((r) => identical(r.ref.target, object));
    if (existing != null) return (record: existing, wasAbsent: false);

    final creationChecker = phase.ignoredLeaks.createdByTestHelpers
        ? CreationChecker(
            creationStack: StackTrace.current,
            exceptions: phase.ignoredLeaks.testHelperExceptions)
        : null;

    final result = ObjectRecord(
      object,
      context,
      trackedClass,
      phase,
      creationChecker: creationChecker,
    );

    list.add(result);
    _length++;
    return (record: result, wasAbsent: true);
  }

  int _length = 0;
  int get length => _length;

  Iterable<ObjectRecord> toIterable() {
    return _records.values.expand((list) => list);
  }
}
