// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../../test_infra/flutter_classes.dart';
import '../../test_infra/leak_tracking_in_flutter.dart';

const test1TrackingOn = 'test1, tracking-on';
const test2TrackingOff = 'test2, tracking-off';
const test3TrackingOn = 'test3, tracking-on';

/// Tests for non-mocked public API of leak tracker.
///
/// For this tests `expect` for found leaks happens in flitter_test_config.dart.
void main() {
  testWidgetsWithLeakTracking(test1TrackingOn, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, test1TrackingOn);
    expect(LeakTracking.phase.isPaused, false);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgets(test2TrackingOff, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, null);
    expect(LeakTracking.phase.isPaused, true);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgetsWithLeakTracking(test3TrackingOn, (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, test3TrackingOn);
    expect(LeakTracking.phase.isPaused, false);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });
}
