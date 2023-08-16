// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Test configuration for each test library in this directory.
///
/// See https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  var leaksDetected = false;

  setLeakTrackingTestSettings(
    LeakTrackingTestSettings(
      switches: const Switches(disableNotDisposed: true),
    ),
  );

  // This tear down should be set before leak tracking tear down in
  // order to happen after it and verify that leaks are found.
  tearDownAll(() async {
    expect(leaksDetected, true, reason: 'leaks should be detected');
  });

  configureLeakTrackingTearDown(
    configureOnce: true,
    onLeaks: (leaks) {
      // Check that notDisposed leaks are skipped.
      expect(leaks.notDisposed, hasLength(0));
      expect(leaks.notGCed, hasLength(1));
      expect(leaks.gcedLate, hasLength(0));
      leaksDetected = true;
    },
  );

  setUpAll(() {
    LeakTracking.warnForUnsupportedPlatforms = false;
  });

  await testMain();
}
