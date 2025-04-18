// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/leak_tracking/_object_record.dart';
import 'package:leak_tracker/src/leak_tracking/_object_record_set.dart';
import 'package:leak_tracker/src/leak_tracking/primitives/model.dart';
import 'package:leak_tracker/src/shared/_primitives.dart';
import 'package:test/test.dart';

bool _tick = true;

final _coders = <String, IdentityHashCoder>{
  'real': standardIdentityHashCoder,
  'alwaysTheSame': (object) => 1,
  'alterative': (object) => (_tick = !_tick) ? 1 : 2,
};

const _phase = PhaseSettings();
final _record = ObjectRecord([], {}, '', _phase);

void main() {
  for (var coderName in _coders.keys) {
    test('$ObjectRecordSet works well with $coderName', () {
      final items = [
        [0],
        [1],
        [2],
      ];

      final theSet = ObjectRecordSet(coder: _coders[coderName]!);

      final records = items.map((i) => _addItemAndValidate(theSet, i)).toList();

      expect(records[0], isNot(records[1]));
      expect(records[1], isNot(records[2]));
      expect(records[0], isNot(records[2]));

      for (var r in records) {
        _removeItemAndValidate(theSet, r);
      }
    });
  }
}

ObjectRecord _addItemAndValidate(ObjectRecordSet theSet, Object item) {
  final length = theSet.length;

  // Add first time.
  final (record: record1, wasAbsent: wasAbsent1) =
      theSet.putIfAbsent(item, {}, _phase, '');
  expect(theSet.length, length + 1);
  expect(theSet.contains(record1), true);
  expect(theSet.contains(_record), false);
  expect(wasAbsent1, true);

  // Add second time.
  final (record: record2, wasAbsent: wasAbsent2) =
      theSet.putIfAbsent(item, {}, _phase, '');
  expect(identical(record1, record2), true);
  expect(theSet.length, length + 1);
  expect(wasAbsent2, false);

  var count = 0;
  theSet.toIterable().forEach((record) => count++);
  expect(count, theSet.length);

  expect(theSet.record(item), record1);

  return record1;
}

void _removeItemAndValidate(ObjectRecordSet theSet, ObjectRecord record) {
  final length = theSet.length;

  expect(theSet.contains(record), true);
  expect(theSet.contains(_record), false);
  theSet.remove(record);
  expect(theSet.length, length - 1);
  expect(theSet.contains(record), false);
  expect(theSet.contains(_record), false);

  var count = 0;
  theSet.toIterable().forEach((record) => count++);
  expect(count, theSet.length);

  expect(theSet.record(record.ref.target!), null);
}
