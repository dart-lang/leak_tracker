// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../../test_infra/leak_tracking_in_flutter.dart';

void main() {
  testWidgetsWithLeakTracking(
    'baseline',
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      for (var i = 0; i < 1000; i++) {
        await widgetTester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              height: 10 + i % 2,
              child: const Icon(Icons.abc),
            ),
          ),
        );
      }
    },
    leakTrackingTestConfig: LeakTrackingTestConfig(
      baselining: MemoryBaselining(
        baseline: MemoryBaseline(
          rss: ValueSampler(
            initialValue: 180486144,
            deltaAvg: 52365240.11495881,
            deltaMax: 76480512,
            absAvg: 232839051.2746114,
            absMax: 256966656,
            samples: 4245,
          ),
        ),
      ),
    ),
  );
}
