// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'failure_test.dart';

/// The test configuration for each test library in this directory.
///
/// See https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Leaks? leaks;

  // This tear down should be set before leak tracking tear down in
  // order to happen after it and verify that leaks are found.
  tearDownAll(() async {
    final theLeaks = leaks;
    if (theLeaks == null) throw 'leaks should be detected';

    expect(
      theLeaks.notDisposed.where((l) => l.phase == twoControllers),
      hasLength(2),
    );
  });

  configureLeakTrackingTearDown(
    configureOnce: true,
    onLeaks: (l) => leaks = l,
  );

  setUpAll(() {
    LeakTracking.warnForUnsupportedPlatforms = false;
  });

  await testMain();
}
