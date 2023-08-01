// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:leak_tracker/src/shared/shared_model.dart';
import 'package:test/test.dart';

void main() {
  test('$Leaks serializes.', () {
    final leaks = Leaks({
      LeakType.gcedLate: [
        LeakReport(
          trackedClass: 'trackedClass1',
          type: 't1',
          context: {'a': 1, 'b': 3.14, 'c': ''},
          code: 1,
          phase: null,
        ),
      ],
      LeakType.notDisposed: [
        LeakReport(
          trackedClass: 'trackedClass2',
          type: 't2',
          context: {},
          code: 2,
          phase: null,
        ),
      ],
      LeakType.notGCed: [
        LeakReport(
          trackedClass: 'trackedClass3',
          type: 't3',
          context: {},
          code: 1,
          phase: null,
        ),
      ],
    });

    final json = leaks.toJson();

    expect(
      jsonEncode(json),
      jsonEncode(Leaks.fromJson(json).toJson()),
    );
  });

  test('$LeakSummary serializes.', () {
    final leakSummary = LeakSummary(
      {
        LeakType.gcedLate: 2,
        LeakType.notDisposed: 3,
        LeakType.notGCed: 4,
      },
      time: DateTime(2022),
    );

    final json = leakSummary.toJson();

    expect(
      jsonEncode(json),
      jsonEncode(LeakSummary.fromJson(json).toJson()),
    );
  });
}
