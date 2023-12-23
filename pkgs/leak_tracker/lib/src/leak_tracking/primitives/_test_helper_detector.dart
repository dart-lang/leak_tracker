// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Frames pointing the folder `test` or the package `flutter_test`.
const _testHelperFrame = r'(?:\/test\/|\(package:flutter_test\/)';

/// Stack frame, containing this string, is start of a test.
const _testStartFrame =
    r'(?:TestAsyncUtils.guard.<anonymous closure>| main.<anonymous closure>)';

const _anyText = r'[\S\s]*';

final _expr =
    RegExp('$_testHelperFrame$_anyText$_testStartFrame', multiLine: true);

bool isCreatedByTestHelper(String trace) {
  // print(trace);
  // print('\n\n\n');
  final result = _expr.hasMatch(trace);
  // print(result);
  // print('\n\n\n');
  return result;
}
