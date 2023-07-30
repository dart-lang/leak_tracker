// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../test_infra/leak_tracking_in_flutter.dart';
import 'flutter_test_config_test.dart';

/// Test configuration for each test library in this directory.
///
/// See https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() {
    LeakTracking.warnForNotSupportedPlatforms = false;
    setUpTestingWithLeakTracking();
  });

  tearDownAll(() async {
    try {
      await tearDownTestingWithLeakTracking();
    } catch (e) {
      if (e is! TestFailure) {
        rethrow;
      }
      expect(e.message, contains('test: $test1TrackingOn'));
      expect(e.message!.contains(test2TrackingOff), false);
      print(e.message);
    }
  });

  await testMain();
}
