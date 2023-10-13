// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/src/leak_tracking_for_tests.dart';

void main() {
  test('$LeakTrackingForTestsSettings can be started and paused.', () async {
    expect(LeakTrackingForTests.settings.paused, true);
    LeakTrackingForTests.start();
    expect(LeakTrackingForTests.settings.paused, false);
    LeakTrackingForTests.pause();
    expect(LeakTrackingForTests.settings.paused, true);
  });

  test(
      '$LeakTrackingForTestsSettings can be altered globally or for a library.',
      () async {
    const myClass = 'MyClass';
    const myNotDisposed = 'MyNotDisposedClass';
    const myNotGCed = 'myNotGCedClass';

    bool isSkipped(String className, {LeakType? leakType}) =>
        LeakTrackingForTests.settings.leakSkipLists
            .isSkipped(className, leakType: leakType);

    // Verify initial settings.
    expect(isSkipped(myClass), false);
    expect(isSkipped(myClass, leakType: LeakType.notDisposed), false);
    expect(isSkipped(myClass, leakType: LeakType.notGCed), false);

    // Skip some classes.
    LeakTrackingForTests.skip(
      classes: [myClass],
      notGCed: {myNotGCed: null},
      notDisposed: {myNotDisposed: null},
    );

    // Verify the change.
    expect(isSkipped(myClass), true);
    expect(isSkipped(myNotDisposed), false);
    expect(isSkipped(myNotGCed), false);

    expect(isSkipped(myClass, leakType: LeakType.notDisposed), true);
    expect(isSkipped(myNotDisposed, leakType: LeakType.notDisposed), true);
    expect(isSkipped(myNotGCed, leakType: LeakType.notDisposed), false);

    expect(isSkipped(myClass, leakType: LeakType.notGCed), true);
    expect(isSkipped(myNotDisposed, leakType: LeakType.notGCed), false);
    expect(isSkipped(myNotGCed, leakType: LeakType.notGCed), true);

    // Start tracking classes.
    LeakTrackingForTests.track(
      classes: [myClass],
      notGCed: [myNotGCed],
      notDisposed: [myNotDisposed],
    );

    // Verify the change.
    expect(isSkipped(myClass), false);
    expect(isSkipped(myNotDisposed), false);
    expect(isSkipped(myNotGCed), false);

    expect(isSkipped(myClass, leakType: LeakType.notDisposed), false);
    expect(isSkipped(myNotDisposed, leakType: LeakType.notDisposed), false);
    expect(isSkipped(myNotGCed, leakType: LeakType.notDisposed), false);

    expect(isSkipped(myClass, leakType: LeakType.notGCed), false);
    expect(isSkipped(myNotDisposed, leakType: LeakType.notGCed), false);
    expect(isSkipped(myNotGCed, leakType: LeakType.notGCed), false);
  });

  test('$LeakTrackingForTestsSettings can be altered for and individual test.',
      () async {
    const myClass = 'MyClass';
    const myNotDisposed = 'MyNotDisposedClass';
    const myNotGCed = 'myNotGCedClass';

    // Skip some classes.
    LeakTrackingForTests.skip(
      classes: [myClass],
    );

    final testSettings = LeakTrackingForTests.withSkipped(
      notGCed: {myNotGCed: null},
      notDisposed: {myNotDisposed: null},
    );

    bool isSkipped(String className, {LeakType? leakType}) =>
        testSettings.leakSkipLists.isSkipped(className, leakType: leakType);

    // Verify the change.
    expect(isSkipped(myClass), true);
    expect(isSkipped(myNotDisposed), false);
    expect(isSkipped(myNotGCed), false);

    expect(isSkipped(myClass, leakType: LeakType.notDisposed), true);
    expect(isSkipped(myNotDisposed, leakType: LeakType.notDisposed), true);
    expect(isSkipped(myNotGCed, leakType: LeakType.notDisposed), false);

    expect(isSkipped(myClass, leakType: LeakType.notGCed), true);
    expect(isSkipped(myNotDisposed, leakType: LeakType.notGCed), false);
    expect(isSkipped(myNotGCed, leakType: LeakType.notGCed), true);
  });
}
