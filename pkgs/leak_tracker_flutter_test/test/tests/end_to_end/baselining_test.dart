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
      await widgetTester.pumpWidget(
        const MaterialApp(home: SizedBox(child: Icon(Icons.abc))),
      );
    },
    leakTrackingTestConfig: LeakTrackingTestConfig(
      // baselining: MemoryBaselining(
      //   mode: BaseliningMode.compare,
      //   baseline:  MemoryBaseline(
      //     rss: ValueSampler(initialValue: 143933440, deltaAvg: 0.0, deltaMax: 0, samples: 0,),
      //   ),
      // )
      baselining: MemoryBaselining(),
    ),
  );
}
