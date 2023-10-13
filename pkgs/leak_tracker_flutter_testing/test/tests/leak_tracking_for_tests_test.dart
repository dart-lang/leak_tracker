// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/src/leak_tracking_for_tests.dart';

class _Classes {
  static const allTypes1 = 'allTypes1';
  static const notDisposed1 = 'notDisposed1';
  static const notGCed1 = 'notGCed1';

  static const allTypes2 = 'allTypes2';
  static const notDisposed2 = 'notDisposed2';
  static const notGCed2 = 'notGCed2';

  static final all = [
    allTypes1,
    allTypes2,
    notDisposed1,
    notDisposed2,
    notGCed1,
    notGCed2,
  ];

  static List<String> others(List<String> classes) =>
      all.where((c) => !classes.contains(c)).toList();
}

bool _areOnlyAllowed(
  List<String> classes, {
  LeakType? leakType,
}) {
  final classesAllowed = !classes
      .map(
        (theClass) => LeakTrackingForTests.settings.leakSkipLists
            .isAllowed(theClass, leakType: leakType),
      )
      .any((allowed) => !allowed);
  final othersDisallowed = _Classes.others(classes)
      .map(
        (theClass) => LeakTrackingForTests.settings.leakSkipLists
            .isAllowed(theClass, leakType: leakType),
      )
      .any((allowed) => !allowed);
  return classesAllowed && othersDisallowed;
}

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
            .isAllowed(className, leakType: leakType);

    // Verify initial settings.
    expect(isSkipped(myClass), false);
    expect(isSkipped(myClass, leakType: LeakType.notDisposed), false);
    expect(isSkipped(myClass, leakType: LeakType.notGCed), false);

    // Skip some classes.
    LeakTrackingForTests.allow(
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

  test('$LeakTrackingForTestsSettings can be altered iteratively.', () async {
    // Verify initial settings.
    expect(_areOnlyAllowed([]), true);
    expect(_areOnlyAllowed([], leakType: LeakType.notDisposed), true);
    expect(_areOnlyAllowed([], leakType: LeakType.notGCed), true);

    // Allow some classes.
    LeakTrackingForTests.allow(
      classes: [_Classes.allTypes1],
      notGCed: {_Classes.notGCed1: null},
      notDisposed: {_Classes.notDisposed1: null},
    );

    // Verify the change.
    expect(_areOnlyAllowed([_Classes.allTypes1]), true);
    expect(
      _areOnlyAllowed(
        [_Classes.allTypes1, _Classes.notDisposed1],
        leakType: LeakType.notDisposed,
      ),
      true,
    );
    expect(
      _areOnlyAllowed(
        [_Classes.allTypes1, _Classes.notGCed1],
        leakType: LeakType.notGCed,
      ),
      true,
    );

    // Allow more classes.
    LeakTrackingForTests.allow(
      classes: [_Classes.allTypes2],
      notGCed: {_Classes.notGCed2: null},
      notDisposed: {_Classes.notDisposed2: null},
    );

    // Verify the change.
    expect(_areOnlyAllowed([_Classes.allTypes1, _Classes.allTypes2]), true);
    expect(
      _areOnlyAllowed(
        [
          _Classes.allTypes1,
          _Classes.notDisposed1,
          _Classes.allTypes2,
          _Classes.notDisposed2
        ],
        leakType: LeakType.notDisposed,
      ),
      true,
    );
    expect(
      _areOnlyAllowed(
        [
          _Classes.allTypes1,
          _Classes.notGCed1,
          _Classes.allTypes2,
          _Classes.notGCed2
        ],
        leakType: LeakType.notGCed,
      ),
      true,
    );
  });

  test('$LeakTrackingForTestsSettings can be altered for and individual test.',
      () async {
    const myClass = 'MyClass';
    const myNotDisposed = 'MyNotDisposedClass';
    const myNotGCed = 'myNotGCedClass';

    // Skip some classes.
    LeakTrackingForTests.allow(
      classes: [myClass],
    );

    final testSettings = LeakTrackingForTests.withSkipped(
      notGCed: {myNotGCed: null},
      notDisposed: {myNotDisposed: null},
    );

    bool isSkipped(String className, {LeakType? leakType}) =>
        testSettings.leakSkipLists.isAllowed(className, leakType: leakType);

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
