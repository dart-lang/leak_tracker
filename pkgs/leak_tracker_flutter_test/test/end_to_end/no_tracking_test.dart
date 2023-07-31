// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../test_infra/flutter_classes.dart';
import '../test_infra/leak_tracking_in_flutter.dart';

const test0TrackingOff = 'test0, tracking-off';
const test1TrackingOn = 'test1, tracking-on';
const test2TrackingOff = 'test2, tracking-off';
const test3TrackingOn = 'test3, tracking-on';

void main() {
  testWidgets(
      'Leak tracking is not started without `testWidgetsWithLeakTracking`',
      (widgetTester) async {
    expect(LeakTracking.isStarted, false);
    expect(LeakTracking.phase.name, null);
    expect(LeakTracking.phase.isPaused, true);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });
}
