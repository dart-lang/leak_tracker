// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:matcher/expect.dart';

typedef PumpWidgetsCallback = Future<void> Function(
  Widget widget, [
  Duration? duration,
]);

typedef RunAsyncCallback<T> = Future<T?> Function(
  Future<T> Function() callback,
);

typedef TestCallback = Future<void> Function(
  PumpWidgetsCallback? pumpWidgetsCallback,
  RunAsyncCallback<dynamic>? runAsyncCallback,
);

class TestCase {
  final String name;
  final TestCallback body;
  final int notDisposedTotal;
  final int notGCedTotal;
  final int notDisposedInHelpers;
  final int notGCedInHelpers;

  TestCase({
    required this.name,
    required this.body,
    this.notDisposedTotal = 0,
    this.notGCedTotal = 0,
    this.notDisposedInHelpers = 0,
    this.notGCedInHelpers = 0,
  });

  /// Verifies [leaks] contain expected number of leaks for the test [testDescription].
  void _verifyLeaks(Leaks leaks, String testDescription, LeakTesting settings) {
    for (final LeakType type in expectedContextKeys.keys) {
      final List<LeakReport> leaks = testLeaks.byType[type] ?? <LeakReport>[];
      final List<String> expectedKeys = expectedContextKeys[type]!..sort();
      for (final LeakReport leak in leaks) {
        final List<String> actualKeys =
            leak.context?.keys.toList() ?? <String>[];
        expect(actualKeys..sort(), equals(expectedKeys),
            reason: '$testDescription, $type');
      }
    }

    _verifyLeakList(
      testLeaks.notDisposed,
      notDisposed,
      name,
    );
    _verifyLeakList(
      testLeaks.notGCed,
      notGCed,
      testDescription,
    );
  }

  void _verifyLeakList(
    List<LeakReport> list,
    int expectedTotalLeaks,
    int expectedInHelpersLeaks,
    String testDescription,
    List<String> expectedContextKeys,
    bool ignoreHelpers,
  ) {
    final expectedCount = ignoreHelpers
        ? expectedTotalLeaks - expectedInHelpersLeaks
        : expectedTotalLeaks;

    expect(list.length, expectedCount, reason: testDescription);
  }
}
