// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:test/test.dart';

final LeakTesting settings =
    LeakTesting.settings.withIgnored(allNotDisposed: true, allNotGCed: true);

void main() {
  group('maybeSetupLeakTrackingForTest', () {
    setUp(() {
      LeakTesting.enable();
      LeakTesting.settings = LeakTesting.settings.withTrackedAll();
    });

    tearDown(LeakTracking.stop);

    test('If settings is null, respects globals', () {
      maybeSetupLeakTrackingForTest(null, 'myTest1');
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, 'myTest1');
      expect(LeakTracking.phase.ignoreLeaks, LeakTesting.settings.ignore);
      expect(
        LeakTracking.phase.ignoredLeaks,
        LeakTesting.settings.ignoredLeaks,
      );
    });

    test('If settings are provided, respects them', () {
      maybeSetupLeakTrackingForTest(settings, 'myTest2');
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, 'myTest2');
      expect(LeakTracking.phase.ignoreLeaks, settings.ignore);
      expect(
        LeakTracking.phase.ignoredLeaks,
        settings.ignoredLeaks,
      );
    });
  });

  group('maybeTearDownLeakTrackingForTest', () {
    setUp(() {
      LeakTesting.settings = LeakTesting.settings.withTrackedAll();
      maybeSetupLeakTrackingForTest(null, 'myTest1');
    });

    tearDown(LeakTracking.stop);

    test('Pauses leak tracking and can be invoked twice', () {
      maybeTearDownLeakTrackingForTest();
      expect(LeakTracking.phase.name, null);
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.ignoreLeaks, true);

      maybeTearDownLeakTrackingForTest();
      expect(LeakTracking.phase.name, null);
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.ignoreLeaks, true);
    });
  });

  group('maybeTearDownLeakTrackingForAll', () {
    setUp(() {
      LeakTesting.settings = LeakTesting.settings.withTrackedAll();
      maybeSetupLeakTrackingForTest(null, 'myTest1');
      maybeTearDownLeakTrackingForTest();
    });

    tearDown(LeakTracking.stop);

    test('Stops leak tracking', () async {
      await maybeTearDownLeakTrackingForAll();
      expect(LeakTracking.isStarted, false);
    });
  });
}
