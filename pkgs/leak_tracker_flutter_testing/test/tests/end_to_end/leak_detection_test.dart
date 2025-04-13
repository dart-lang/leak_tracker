// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:test/test.dart';

import '../../test_infra/memory_leak_tests.dart';

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
  LeakTesting.settings = LeakTesting.settings.withIgnored(
    createdByTestHelpers: true,
    testHelperExceptions: [RegExp(RegExp.escape(memoryLeakTestsFilePath()))],
  );

  tearDown(maybeTearDownLeakTrackingForTest);

  for (final t in memoryLeakTests) {
    for (final settingsCase in leakTestingSettingsCases.entries) {
      final settings = settingsCase.value(LeakTesting.settings);
      final execution = _TestExecution(
          settingName: settingsCase.key, test: t, settings: settings);
      _testExecutions.add(execution);

      test(execution.name, () async {
        maybeSetupLeakTrackingForTest(settings, execution.name);
        await t.body(null, null);
      });
    }
  }
}

void _verifyLeaks(Leaks leaks) {
  for (final execution in _testExecutions) {
    final testLeaks = leaks.byPhase[execution.name] ?? Leaks.empty();
    execution.test.verifyLeaks(testLeaks, execution.settings,
        testDescription: execution.name);
  }
}
