// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/shared/shared_model.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'package:test/test.dart';

final _leaks = Leaks({
  LeakType.gcedLate: [
    LeakReport(
      trackedClass: 'trackedClass',
      context: {},
      code: 1,
      type: 'type',
      phase: null,
    ),
  ],
});

void main() {
  test('$isLeakFree passes.', () async {
    expect(Leaks({}), isLeakFree);
  });

  test('$isLeakFree fails.', () async {
    expect(isLeakFree.matches(_leaks, {}), false);
  });
}
