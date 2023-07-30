// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import '../../test_infra/leak_tracking_in_flutter.dart';
import 'phase_settings_test.dart';

/// Test configuration for each test library in this directory.
///
/// See https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  var leaksDetected = false;

  // This tear down should be set before leak tracking tear down in order to happen after it.
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
    },
  );

  setUpAll(() {
    LeakTracking.warnForNotSupportedPlatforms = false;
  });

  tearDownAll(() async {
    print('tear down all 2, leaks detected: $leaksDetected');
    //expect(leaksDetected, true, reason: 'leaks should be detected');
  });

  await testMain();
}
