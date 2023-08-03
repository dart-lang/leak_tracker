// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../../test_infra/flutter_classes.dart';
import '../../test_infra/leak_tracking_in_flutter.dart';

const _test0TrackingOffLeaks = 'test0, tracking-off';
const _test1TrackingOn = 'test1, tracking-on';
const _test2TrackingOffLeaks = 'test2, tracking-off';
const _test3TrackingOn = 'test3, tracking-on';

/// Tests with default leak tracking configuration.
///
/// This set of tests verifies that if `testWidgetsWithLeakTracking` is used at least once,
/// leak tracking is configured as expected, and is noop for `testWidgets`.
void main() {
  testWidgets(_test0TrackingOffLeaks, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, null);
    expect(LeakTracking.phase.isLeakTrackingPaused, true);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgetsWithLeakTracking(_test1TrackingOn, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test1TrackingOn);
    expect(LeakTracking.phase.isLeakTrackingPaused, false);
  });

  testWidgets(_test2TrackingOffLeaks, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, null);
    expect(LeakTracking.phase.isLeakTrackingPaused, true);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgetsWithLeakTracking(_test3TrackingOn, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test3TrackingOn);
    expect(LeakTracking.phase.isLeakTrackingPaused, false);
  });
}