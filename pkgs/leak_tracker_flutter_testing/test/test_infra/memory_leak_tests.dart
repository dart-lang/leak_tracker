// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'test_helpers.dart';

/// Objects that should not be GCed during.
final _retainer = <InstrumentedDisposable>[];

/// Test cases for memory leaks.
///
/// They are separate from test execution to allow
/// excluding them from test helpers.
final List<LeakTestCase> memoryLeakTests = <LeakTestCase>[
  LeakTestCase(
    name: 'no leaks',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      Container();
    },
  ),
  LeakTestCase(
    name: 'not disposed disposable',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      InstrumentedDisposable();
    },
    notDisposedTotal: 1,
  ),
  LeakTestCase(
    name: 'not GCed disposable',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      _retainer.add(InstrumentedDisposable()..dispose());
    },
    notGCedTotal: 1,
  ),
  LeakTestCase(
    name: 'leaking widget',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      StatelessLeakingWidget();
    },
    notDisposedTotal: 1,
    notGCedTotal: 1,
  ),
  LeakTestCase(
    name: 'leaks from test helpers',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      createLeakingWidget();
    },
    notDisposedTotal: 1,
    notGCedTotal: 1,
    notDisposedInHelpers: 1,
    notGCedInHelpers: 1,
  ),
];

String memoryLeakTestsFilePath() {
  return RegExp(r'(\/[^\/]*.dart):')
      .firstMatch(StackTrace.current.toString())!
      .group(1)
      .toString();
}
