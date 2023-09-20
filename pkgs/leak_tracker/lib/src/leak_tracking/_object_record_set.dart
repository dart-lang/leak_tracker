// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../shared/_primitives.dart';
import '_object_record.dart';
import '_primitives/model.dart';

@visibleForTesting
class ObjectRecordSet {
  ObjectRecordSet({this.coder = standardIdentityHashCoder});

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

  void remove(ObjectRecord record) {
    final list = _records[record.code]!;
    bool removed = false;
    list.removeWhere((r) {
      if (r == record) {
        assert(!removed);
        removed = true;
      }
      return r == record;
    });
    assert(removed);
    _length--;
    if (list.isEmpty) _records.remove(record.code);
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
    _length++;
    return result;
  }

  int _length = 0;
  int get length => _length;

  void forEach(void Function(ObjectRecord record) callback) {
    for (var list in _records.values) {
      list.forEach(callback);
    }
  }
}
