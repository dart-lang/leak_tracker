// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:leak_tracker_flutter_testing/src/test_classes.dart';
import 'package:test/test.dart';

/// These tests verify that value of
/// [IgnoredLeaks.createdByTestHelpers] is respected.
void main() {
  setUp(() {
    LeakTesting.collectedLeaksReporter = (leaks) {};
    maybeSetupLeakTrackingForTest(
      LeakTesting.settings.withTrackedAll().withIgnored(
            allNotGCed: true,
            createdByTestHelpers: true,
          ),
      '-',
    );
  });

  tearDown(() {
    maybeTearDownLeakTrackingForAll();
  });

  test('Prod leak is detected.', () async {
    StatelessLeakingWidget();

    LeakTracking.declareNotDisposedObjectsAsLeaks();
    final leaks = await LeakTracking.collectLeaks();
    expect(leaks.notDisposed.length, 1);
  });

  test('Test leak is ignored.', () async {
    createTestWidget();

    LeakTracking.declareNotDisposedObjectsAsLeaks();
    final leaks = await LeakTracking.collectLeaks();
    expect(leaks.notDisposed.length, 0);
  });
}

StatelessLeakingWidget createTestWidget() => StatelessLeakingWidget();
