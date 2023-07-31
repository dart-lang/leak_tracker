// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:test/test.dart';

import '../test_infra/data/dart_classes.dart';

void main() {
  tearDown(() => LeakTracking.stop());

  for (var numberOfGcCycles in [1, defaultNumberOfGcCycles]) {
    test('Passive leak tracking detects leaks, $numberOfGcCycles.', () async {
      LeakTracking.start(
        resetIfAlreadyStarted: true,
        config: LeakTrackingConfig.passive(
          numberOfGcCycles: numberOfGcCycles,
        ),
      );

      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.isPaused, false);

      LeakingClass();
      LeakingClass();
      LeakingClass();

      expect(LeakTracking.phase.isPaused, false);

      await forceGC(fullGcCycles: defaultNumberOfGcCycles);
      final leaks = await LeakTracking.collectLeaks();
      LeakTracking.stop();

      expect(leaks.notGCed, hasLength(3));
      expect(
        () => expect(leaks, isLeakFree),
        throwsA(isA<TestFailure>()),
      );
    });
  }
}
