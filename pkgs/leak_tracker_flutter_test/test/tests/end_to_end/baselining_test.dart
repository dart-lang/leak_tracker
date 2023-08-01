// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../../test_infra/flutter_classes.dart';
import '../../test_infra/leak_tracking_in_flutter.dart';

void main() {
  testWidgetsWithLeakTracking('baseline', (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.isPaused, false);
  },
      leakTrackingTestConfig: const LeakTrackingTestConfig(
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectStackTraceOnStart: true,
        ),
      ));
}
