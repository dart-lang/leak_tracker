// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Frames pointing the folder `test` or the package `flutter_test`.
final _testHelperFrame = RegExp(r'(?:\/test\/|\(package:flutter_test\/)');

/// Frames that match [_testHelperFrame], but are not test helpers.
final _exception = RegExp(
    r'(?:WidgetTester.runAsync \(package:flutter_test/src/widget_tester.dart:)');

/// Start of a test or closure inside test.
final _startFrame = RegExp(
    r'(?:TestAsyncUtils.guard.<anonymous closure>| main.<anonymous closure>)');

bool isCreatedByTestHelper(String trace, List<RegExp> exceptions) {
  final frames = trace.split('\n');
  for (final frame in frames) {
    if (_startFrame.hasMatch(frame)) {
      return false;
    }
    if (_testHelperFrame.hasMatch(frame)) {
      if (exceptions.any((exception) => exception.hasMatch(frame)) ||
          _exception.hasMatch(frame)) {
        continue;
      }
      return true;
    }
  }
  return false;
}
