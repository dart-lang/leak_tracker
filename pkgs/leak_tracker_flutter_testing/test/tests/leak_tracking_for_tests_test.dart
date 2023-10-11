// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/src/leak_tracking_for_tests.dart';

void main() {
  test('$LeakTrackingForTestsSettings can be altered by levels', () async {
    const myClass = 'MyClass';
    expect(_isTracked(myClass), false);
    //LeakTrackingForTests.
  });
}

bool _isTracked(String className) =>
    LeakTrackingForTests.settings.leakSkipLists.isSkipped(className);
