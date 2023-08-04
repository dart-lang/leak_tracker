// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../../test_infra/leak_tracking_in_flutter.dart';

int _seed = 0;

void main() {
  testWidgetsWithLeakTracking(
    'baseline',
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
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
        repeatCount: 1000,
        gcBefore: true,
        baseline: MemoryBaseline(
          rss: ValueSampler(
            initialValue: 179748864,
            deltaAvg: 52202774.13239106,
            deltaMax: 74547200,
            absAvg: 231939343.555346,
            absMax: 254296064,
            samples: 4245,
          ),
        ),
      ),
    ),
  );
}
