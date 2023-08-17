// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

int _seed = 0;

void main() {
  testWidgetsWithLeakTracking(
    'baseline',
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.isLeakTrackingPaused, true);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 10 +
                (_seed++) %
                    101, // We need some change to avoid constant values.
            child: const Icon(Icons.abc),
          ),
        ),
      );
    },
    leakTrackingTestConfig: LeakTrackingTestConfig(
      isLeakTrackingPaused: true,
      baselining: MemoryBaselining(
        baseline: MemoryBaseline(
          rss: ValueSampler(
            initialValue: 144719872,
            deltaAvg: 8060928.0,
            deltaMax: 13631488,
            absAvg: 152748556.288,
            absMax: 158351360,
            samples: 249,
          ),
        ),
      ),
    ),
  );
}
