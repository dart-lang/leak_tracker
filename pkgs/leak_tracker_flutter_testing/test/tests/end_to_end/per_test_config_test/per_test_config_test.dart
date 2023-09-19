// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import '../../../test_infra/flutter_classes.dart';

const test1TrackingOnNoLeaks = 'test1, tracking-on, no leaks';
const test2TrackingOffLeaks = 'test2, tracking-off, leaks';
const test3TrackingOnLeaks = 'test3, tracking-on, leaks';
const test4TrackingOnWithStackTrace = 'test4, tracking-on, with stack trace';
const test5TrackingOnWithPath = 'test5, tracking-on, with path';

/// For these tests `expect` for found leaks happens in flutter_test_config.dart.
void main() {
  testWidgetsWithLeakTracking(test1TrackingOnNoLeaks, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, test1TrackingOnNoLeaks);
    expect(LeakTracking.phase.isLeakTrackingPaused, false);
    await widgetTester.pumpWidget(Container());
  });

  testWidgets(test2TrackingOffLeaks, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, null);
    expect(LeakTracking.phase.isLeakTrackingPaused, true);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgetsWithLeakTracking(test3TrackingOnLeaks, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, test3TrackingOnLeaks);
    expect(LeakTracking.phase.isLeakTrackingPaused, false);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgetsWithLeakTracking(
    test4TrackingOnWithStackTrace,
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, test4TrackingOnWithStackTrace);
      expect(LeakTracking.phase.isLeakTrackingPaused, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
    leakTrackingTestConfig: LeakTrackingTestConfig.debug(),
  );

  testWidgetsWithLeakTracking(
    test5TrackingOnWithPath,
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, test5TrackingOnWithPath);
      expect(LeakTracking.phase.isLeakTrackingPaused, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
    leakTrackingTestConfig: const LeakTrackingTestConfig.retainingPath(),
  );
}
