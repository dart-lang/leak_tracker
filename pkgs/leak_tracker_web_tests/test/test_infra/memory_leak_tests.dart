// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'test_helpers.dart';

/// Test cases for memory leaks.
///
/// They are separate from test execution to allow
/// excluding them from test helpers.
final List<LeakTestCase> memoryLeakTests = <LeakTestCase>[
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

String memoryLeakTestsFilePath() {
  try {
    final result = RegExp(
      r'(\/[^\/]*_tests.dart.js)',
    ).firstMatch(StackTrace.current.toString())!.group(1).toString();
    return result;
  } catch (e, s) {
    throw Exception('Failed to get test file path: $e, $s');
  }
}
