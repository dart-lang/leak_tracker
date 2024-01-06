// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Frames pointing the folder `test` or the package `flutter_test`.
final _testHelperFrame = RegExp(
  r'(?:' +
      RegExp.escape(r'/test/') +
      r'|' +
      RegExp.escape(r'(package:flutter_test/') +
      r')',
);

/// Frames that match [_testHelperFrame], but are not test helpers.
final _exceptions = RegExp(
  r'(?:'
  r'AutomatedTestWidgetsFlutterBinding.\w|'
  r'WidgetTester.\w'
  ')',
);

/// Test body or closure inside test body.
final _startFrame = RegExp(
  r'(?:'
  r'TestAsyncUtils.guard.<anonymous closure>|'
  r' main.<anonymous closure>'
  r')',
);

bool isCreatedByTestHelper(String trace, List<RegExp> exceptions) {
  final frames = trace.split('\n');
  for (final frame in frames) {
    if (_startFrame.hasMatch(frame)) {
      return false;
    }
    if (_testHelperFrame.hasMatch(frame)) {
      if (exceptions.any((exception) => exception.hasMatch(frame)) ||
          _exceptions.hasMatch(frame)) {
        continue;
      }
      return true;
    }
  }
  return false;
}
