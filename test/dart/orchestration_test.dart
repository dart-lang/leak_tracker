// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/orchestration.dart';
import 'package:leak_tracker/src/shared_model.dart';
import 'package:test/test.dart';

final _leaks = Leaks({
  LeakType.gcedLate: [
    LeakReport(
      trackedClass: 'trackedClass',
      context: {},
      code: 1,
      type: 'type',
    ),
  ]
});

// TODO(polina-c): add more test coverage for the matcher.

void main() {
  test('No leaks matcher passes.', () async {
    expect(Leaks({}), isLeakFree);
  });

  test('No leaks matcher fails.', () async {
    expect(isLeakFree.matches(_leaks, {}), false);
  });

  test('$withLeakTracking does not fail after exception.', () async {
    const exception = 'some exception';
    try {
      await withLeakTracking(() => throw exception);
    } catch (e) {
      expect(e, exception);
    }

    await withLeakTracking(() async {});
  });
}
