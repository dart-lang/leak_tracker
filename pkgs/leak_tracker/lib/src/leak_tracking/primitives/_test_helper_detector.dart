// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Frames pointing the folder `test` or the package `flutter_test`.
const _testHelperFrame = r'(?:\/test\/|\(package:flutter_test\/)';

/// Frames inside flutter_test, but not pointing a test helper.
const _exception =
    r'(?:WidgetTester.runAsync \(package:flutter_test/src/widget_tester.dart:)';

/// Start of a test or closure inside test.
const _startFrame =
    r'(?:TestAsyncUtils.guard.<anonymous closure>| main.<anonymous closure>)';

bool isCreatedByTestHelper(String trace) {
  final frames = trace.split('\n');
  for (final frame in frames) {
    if (RegExp(_exception).hasMatch(frame)) continue;
    if (RegExp(_testHelperFrame).hasMatch(frame)) return true;
    if (RegExp(_startFrame).hasMatch(frame)) return false;
  }
  return false;
}
