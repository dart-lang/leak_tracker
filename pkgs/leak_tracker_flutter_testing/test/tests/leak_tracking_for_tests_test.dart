// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/src/leak_tracking_for_tests.dart';

void main() {
  test('$LeakTrackingForTestsSettings can be altered by levels', () async {
    const myClass = 'MyClass';

    // Check initial settings.
    expect(LeakTrackingForTests.settings.paused, true);
    expect(_isSkipped(myClass), false);

    // Change settings for package or folder.

    // Change settings for library.

    // Set settings for test.
  });
}

bool _isSkipped(String className) =>
    LeakTrackingForTests.settings.leakSkipLists.isSkipped(className);
