// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:matcher/expect.dart';

/// Signature of `pumpWidget` method.
typedef PumpWidgetsCallback = Future<void> Function(
  Widget widget, [
  Duration? duration,
]);

/// Signature of `runAsync` method.
typedef RunAsyncCallback<T> = Future<T?> Function(
  Future<T> Function() callback,
);

/// Callback for test body, with access to Flutter specific test methods.
typedef TestCallback = Future<void> Function(
  PumpWidgetsCallback? pumpWidgets,
  RunAsyncCallback<dynamic>? runAsync,
);

/// A test case to verify leak detection.
class LeakTestCase {
  LeakTestCase({
    required this.name,
    required this.body,
    this.notDisposedTotal = 0,
    this.notGCedTotal = 0,
    this.notDisposedInHelpers = 0,
    this.notGCedInHelpers = 0,
  });

  /// Name of the test.
  final String name;

  /// Test body.
  final TestCallback body;

  /// Expected number of not disposed objects.
  final int notDisposedTotal;

  /// Expected number of not GCed objects.
  final int notGCedTotal;

  /// Expected number of not disposed objects created by test helpers.
  final int notDisposedInHelpers;

  /// Expected number of not GCed objects created by test helpers.
  final int notGCedInHelpers;

  /// Verifies [leaks] contain expected leaks for the test.
  ///
  /// [settings] is used to determine:
  /// * if some leaks should be ignored
  /// * which diagnostics should be collected
  ///
  /// [testDescription] is used in description for the failed expectations.
  void verifyLeaks(Leaks leaks, LeakTesting settings,
      {required String testDescription}) {
    final expectedContextKeys = <String>[
      if (settings.leakDiagnosticConfig.collectStackTraceOnStart)
        ContextKeys.startCallstack,
    ];

    _verifyLeakList(
      testDescription,
      LeakType.notDisposed,
      leaks,
      ignore: settings.ignore || settings.ignoredLeaks.notDisposed.ignoreAll,
      expectedCount: notDisposedTotal -
          (settings.ignoredLeaks.createdByTestHelpers
              ? notDisposedInHelpers
              : 0),
      expectedContextKeys: expectedContextKeys,
    );

    // Add diagnostics that is relevant for notGCed only.
    if (settings.leakDiagnosticConfig.collectRetainingPathForNotGCed) {
      expectedContextKeys.add(ContextKeys.retainingPath);
    }
    if (settings.leakDiagnosticConfig.collectStackTraceOnDisposal) {
      expectedContextKeys.add(ContextKeys.disposalCallstack);
    }

    _verifyLeakList(
      testDescription,
      LeakType.notGCed,
      leaks,
      ignore: settings.ignore ||
          settings.ignoredLeaks.experimentalNotGCed.ignoreAll,
      expectedCount: notGCedTotal -
          (settings.ignoredLeaks.createdByTestHelpers ? notGCedInHelpers : 0),
      expectedContextKeys: expectedContextKeys,
    );
  }

  void _verifyLeakList(
    String testDescription,
    LeakType type,
    Leaks leaks, {
    required int expectedCount,
    required List<String> expectedContextKeys,
    required bool ignore,
  }) {
    final list = leaks.byType[type] ?? <LeakReport>[];

    expect(
      list.length,
      ignore ? 0 : expectedCount,
      reason: '$testDescription, $type, ignore: $ignore',
    );

    // Verify context keys.
    for (final leak in list) {
      final actualKeys = leak.context?.keys.toList() ?? <String>[];
      expect(actualKeys..sort(), equals(expectedContextKeys..sort()),
          reason: '$testDescription, $type');
    }
  }
}
