// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

class _TestExecution {
  _TestExecution({
    required this.settings,
    required this.settingName,
    required this.test,
  });

  final String settingName;
  final LeakTesting settings;
  final LeakTestCase test;

  String get name => '${test.name}, $settingName';
}

final List<_TestExecution> _testExecutions = <_TestExecution>[];

void main() {
  LeakTesting.collectedLeaksReporter = _verifyLeaks;
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
      .withTrackedAll()
      .withTracked(allNotDisposed: true, experimentalAllNotGCed: false);

  tearDown(maybeTearDownLeakTrackingForTest);

  for (final t in _memoryLeakTests) {
    final execution = _TestExecution(
      settingName: 'not disposed',
      test: t,
      settings: LeakTesting.settings,
    );
    _testExecutions.add(execution);

    testWidgets(execution.name, (tester) async {
      maybeSetupLeakTrackingForTest(LeakTesting.settings, execution.name);
      await t.body(
        (Widget widget, [Duration? duration]) =>
            tester.pumpWidget(widget, duration: duration),
        (callback) => tester.runAsync(callback),
      );
    });
  }
}

void _verifyLeaks(Leaks leaks) {
  for (final execution in _testExecutions) {
    final testLeaks = leaks.byPhase[execution.name] ?? Leaks.empty();
    execution.test.verifyLeaks(
      testLeaks,
      execution.settings,
      testDescription: execution.name,
    );
  }
}

/// Test cases for memory leaks.
final List<LeakTestCase> _memoryLeakTests = <LeakTestCase>[
  LeakTestCase(
    name: 'no leaks',
    body: (
      PumpWidgetsCallback? pumpWidgets,
      RunAsyncCallback<dynamic>? runAsync,
    ) async {
      Container();
    },
  ),
  LeakTestCase(
    name: 'not disposed disposable',
    body: (
      PumpWidgetsCallback? pumpWidgets,
      RunAsyncCallback<dynamic>? runAsync,
    ) async {
      InstrumentedDisposable();
    },
    notDisposedTotal: 1,
  ),
  LeakTestCase(
    name: 'leaking widget',
    body: (
      PumpWidgetsCallback? pumpWidgets,
      RunAsyncCallback<dynamic>? runAsync,
    ) async {
      StatelessLeakingWidget();
    },
    notDisposedTotal: 1,
  ),
];
