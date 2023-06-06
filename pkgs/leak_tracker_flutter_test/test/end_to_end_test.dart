// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/testing.dart';

import 'test_infra/dart_classes.dart';
import 'test_infra/flutter_classes.dart';
import 'test_infra/helpers.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
///
/// The tests cannot run inside other tests because test nesting is forbidden.
/// So, `expect` happens outside the tests, in `tearDown`.
void main() {
  group('Leak tracker catches that', () {
    late Leaks leaks;

    testWidgetsWithLeakTracking(
      '$StatelessLeakingWidget leaks',
      (WidgetTester tester) async {
        await tester.pumpWidget(StatelessLeakingWidget());
      },
      leakTrackingConfig: LeakTrackingTestConfig(
        onLeaks: (Leaks theLeaks) {
          leaks = theLeaks;
        },
        failTestOnLeaks: false,
      ),
    );

    tearDown(
      () => _verifyLeaks(leaks, expectedNotDisposed: 1, expectedNotGCed: 1),
    );
  });
}

/// Verifies [leaks] contains expected number of leaks for [_LeakTrackedClass].
void _verifyLeaks(
  Leaks leaks, {
  int expectedNotDisposed = 0,
  int expectedNotGCed = 0,
}) {
  const String linkToLeakTracker = 'https://github.com/dart-lang/leak_tracker';

  expect(
    () => expect(leaks, isLeakFree),
    throwsA(
      predicate((Object? e) {
        return e is TestFailure && e.toString().contains(linkToLeakTracker);
      }),
    ),
  );

  _verifyLeakList(leaks.notDisposed, expectedNotDisposed);
  _verifyLeakList(leaks.notGCed, expectedNotGCed);
}

void _verifyLeakList(List<LeakReport> list, int expectedCount) {
  expect(list.length, expectedCount);

  for (final LeakReport leak in list) {
    expect(leak.trackedClass, contains(LeakTrackedClass.library));
    expect(leak.trackedClass, contains('$LeakTrackedClass'));
  }
}
