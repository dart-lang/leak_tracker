// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import '../../test_infra/dart_classes.dart';
import '../../test_infra/leak_tracking_in_flutter.dart';
import 'leak_tracking_config_test.dart';

/// Test configuration for each test library in this directory.
///
/// See https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  var leaksDetected = false;

  // This tear down should be set before leak tracking tear down in
  // order to happen after it and verify that leaks are found.
  tearDownAll(() async {
    expect(leaksDetected, true, reason: 'leaks should be detected');
  });

  configureLeakTrackingTearDown(
    onLeaks: (leaks) {
      expect(leaks.total, greaterThan(0));
      leaksDetected = true;

      try {
        expect(leaks, isLeakFree);
      } catch (e) {
        if (e is! TestFailure) {
          rethrow;
        }
        expect(e.message, contains('test: $test1TrackingOn'));
        expect(e.message!.contains(test2TrackingOff), false);
      }

      _verifyLeaks(
        leaks,
        test1TrackingOn,
        notDisposed: 1,
        notGCed: 1,
        shouldContainDebugInfo: false,
      );
    },
  );

  setUpAll(() {
    LeakTracking.warnForNotSupportedPlatforms = false;
  });

  await testMain();
}

/// Verifies [allLeaks] contains expected number of leaks for the test [testName].
void _verifyLeaks(
  Leaks allLeaks,
  String testName, {
  int notDisposed = 0,
  int notGCed = 0,
  required bool shouldContainDebugInfo,
}) {
  const String linkToLeakTracker = 'https://github.com/dart-lang/leak_tracker';

  final leaks = Leaks(
    allLeaks.byType.map(
      (key, value) =>
          MapEntry(key, value.where((leak) => leak.phase == testName).toList()),
    ),
  );

  if (notDisposed + notGCed > 0) {
    expect(
      () => expect(leaks, isLeakFree),
      throwsA(
        predicate((Object? e) {
          return e is TestFailure && e.toString().contains(linkToLeakTracker);
        }),
      ),
    );
  }

  _verifyLeakList(
    leaks.notDisposed,
    notDisposed,
    shouldContainDebugInfo,
  );
  _verifyLeakList(
    leaks.notGCed,
    notGCed,
    shouldContainDebugInfo,
  );
}

void _verifyLeakList(
  List<LeakReport> list,
  int expectedCount,
  bool shouldContainDebugInfo,
) {
  expect(list.length, expectedCount);

  for (final LeakReport leak in list) {
    if (shouldContainDebugInfo) {
      expect(leak.context, isNotEmpty);
    } else {
      expect(leak.context ?? <String, dynamic>{}, isEmpty);
    }
    expect(leak.trackedClass, contains(LeakTrackedClass.library));
    expect(leak.trackedClass, contains('$LeakTrackedClass'));
  }
}
