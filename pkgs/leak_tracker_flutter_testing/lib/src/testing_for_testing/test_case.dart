// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  PumpWidgetsCallback? pumpWidgets,
  RunAsyncCallback<dynamic>? runAsync,
);

class LeakTestCase {
  final String name;
  final TestCallback body;
  final int notDisposedTotal;
  final int notGCedTotal;
  final int notDisposedInHelpers;
  final int notGCedInHelpers;

  LeakTestCase({
    required this.name,
    required this.body,
    this.notDisposedTotal = 0,
    this.notGCedTotal = 0,
    this.notDisposedInHelpers = 0,
    this.notGCedInHelpers = 0,
  });

  /// Verifies [leaks] contain expected leaks for the test.
  void verifyLeaks(Leaks leaks, LeakTesting settings,
      {required String testDescription}) {
    final expectedContextKeys = <String>[
      if (settings.leakDiagnosticConfig.collectStackTraceOnStart)
        ContextKeys.startCallstack,
      if (settings.leakDiagnosticConfig.collectStackTraceOnDisposal)
        ContextKeys.disposalCallstack,
    ];

    _verifyLeakList(
      testDescription,
      LeakType.notDisposed,
      leaks,
      expectedCount: notDisposedTotal -
          (settings.ignoredLeaks.createdByTestHelpers
              ? notDisposedInHelpers
              : 0),
      expectedContextKeys: expectedContextKeys,
    );

    if (settings.leakDiagnosticConfig.collectRetainingPathForNotGCed) {
      expectedContextKeys.add(ContextKeys.retainingPath);
    }

    _verifyLeakList(
      testDescription,
      LeakType.notGCed,
      leaks,
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
  }) {
    final list = leaks.byType[type] ?? <LeakReport>[];

    expect(
      list.length,
      expectedCount,
      reason: testDescription,
    );

    // Verify context keys.
    for (final leak in list) {
      final actualKeys = leak.context?.keys.toList() ?? <String>[];
      expect(actualKeys..sort(), equals(expectedContextKeys..sort()),
          reason: '$testDescription, $type');
    }
  }
}
