// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:test/test.dart';

class _Classes {
  static const anyLeak1 = 'anyLeak1';
  static const notDisposed1 = 'notDisposed1';
  static const notGCed1 = 'notGCed1';

  static const anyLeak2 = 'anyLeak2';
  static const notDisposed2 = 'notDisposed2';
  static const notGCed2 = 'notGCed2';

  static const anyLeak3 = 'anyLeak3';
  static const notDisposed3 = 'notDisposed3';
  static const notGCed3 = 'notGCed3';

  static final all = [
    anyLeak1,
    anyLeak2,
    anyLeak3,
    notDisposed1,
    notDisposed2,
    notDisposed3,
    notGCed1,
    notGCed2,
    notGCed3,
  ];

  static List<String> others(List<String> classes) =>
      all.where((c) => !classes.contains(c)).toList();
}

/// Returns true, if the provided [classes] are skipped and
/// all other classes from [_Classes] are tracked.
bool _areOnlySkipped(
  List<String> classes, {
  LeakType? leakType,
  LeakTesting? settings,
}) {
  final theSettings = settings ?? LeakTesting.settings;
  final classesSkipped = !classes
      .map(
        (theClass) =>
            theSettings.ignoredLeaks.isIgnored(theClass, leakType: leakType),
      )
      .any((skipped) => !skipped);
  final othersTracked = _Classes.others(classes)
      .map(
        (theClass) =>
            theSettings.ignoredLeaks.isIgnored(theClass, leakType: leakType),
      )
      .any((skipped) => !skipped);
  return classesSkipped && othersTracked;
}

void main() {
  final defaults =
      LeakTesting.settings.withTracked(experimentalAllNotGCed: true);

  setUp(() {
    LeakTesting.settings = defaults;
  });

  test('$LeakTesting can be altered globally or for a library.', () async {
    // Verify initial settings.
    expect(_areOnlySkipped([]), true);
    expect(_areOnlySkipped([], leakType: LeakType.notDisposed), true);
    expect(_areOnlySkipped([], leakType: LeakType.notGCed), true);

    // Skip some classes.
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      classes: [_Classes.anyLeak1],
      notGCed: {_Classes.notGCed1: null},
      notDisposed: {_Classes.notDisposed1: null},
    );

    // Verify the change.
    expect(_areOnlySkipped([_Classes.anyLeak1]), true);
    expect(
      _areOnlySkipped(
        [_Classes.anyLeak1, _Classes.notDisposed1],
        leakType: LeakType.notDisposed,
      ),
      true,
    );
    expect(
      _areOnlySkipped(
        [_Classes.anyLeak1, _Classes.notGCed1],
        leakType: LeakType.notGCed,
      ),
      true,
    );

    // Start tracking classes.
    LeakTesting.settings = LeakTesting.settings.withTracked(
      classes: [_Classes.anyLeak1],
      experimentalNotGCed: [_Classes.notGCed1],
      notDisposed: [_Classes.notDisposed1],
    );

    // Verify the change.
    expect(_areOnlySkipped([]), true);
    expect(_areOnlySkipped([], leakType: LeakType.notDisposed), true);
    expect(_areOnlySkipped([], leakType: LeakType.notGCed), true);
  });

  test('$LeakTesting can be altered iteratively.', () async {
    // Verify initial settings.
    expect(_areOnlySkipped([]), true);
    expect(_areOnlySkipped([], leakType: LeakType.notDisposed), true);
    expect(_areOnlySkipped([], leakType: LeakType.notGCed), true);

    // Skip some classes.
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      classes: [_Classes.anyLeak1],
      notGCed: {_Classes.notGCed1: null},
      notDisposed: {_Classes.notDisposed1: null},
    );

    // Verify the change.
    expect(_areOnlySkipped([_Classes.anyLeak1]), true);
    expect(
      _areOnlySkipped(
        [_Classes.anyLeak1, _Classes.notDisposed1],
        leakType: LeakType.notDisposed,
      ),
      true,
    );
    expect(
      _areOnlySkipped(
        [_Classes.anyLeak1, _Classes.notGCed1],
        leakType: LeakType.notGCed,
      ),
      true,
    );

    // Skip more classes.
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      classes: [_Classes.anyLeak2],
      notGCed: {_Classes.notGCed2: null},
      notDisposed: {_Classes.notDisposed2: null},
    );

    // Verify the change.
    expect(_areOnlySkipped([_Classes.anyLeak1, _Classes.anyLeak2]), true);
    expect(
      _areOnlySkipped(
        [
          _Classes.anyLeak1,
          _Classes.notDisposed1,
          _Classes.anyLeak2,
          _Classes.notDisposed2,
        ],
        leakType: LeakType.notDisposed,
      ),
      true,
    );
    expect(
      _areOnlySkipped(
        [
          _Classes.anyLeak1,
          _Classes.notGCed1,
          _Classes.anyLeak2,
          _Classes.notGCed2,
        ],
        leakType: LeakType.notGCed,
      ),
      true,
    );
  });

  test('$LeakTesting can be altered for and individual test.', () async {
    // Skip some classes.
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      classes: [_Classes.anyLeak1],
    );

    // Verify the change.
    expect(_areOnlySkipped([_Classes.anyLeak1]), true);
    expect(
      _areOnlySkipped([_Classes.anyLeak1], leakType: LeakType.notDisposed),
      true,
    );
    expect(
      _areOnlySkipped([_Classes.anyLeak1], leakType: LeakType.notGCed),
      true,
    );

    // Get adjusted settings.
    final settings = LeakTesting.settings.withIgnored(
      notGCed: {_Classes.notGCed1: null},
      notDisposed: {_Classes.notDisposed1: null},
    );

    // Verify the change.
    expect(_areOnlySkipped([_Classes.anyLeak1], settings: settings), true);
    expect(
      _areOnlySkipped(
        [_Classes.anyLeak1, _Classes.notDisposed1],
        leakType: LeakType.notDisposed,
        settings: settings,
      ),
      true,
    );
    expect(
      _areOnlySkipped(
        [_Classes.anyLeak1, _Classes.notGCed1],
        leakType: LeakType.notGCed,
        settings: settings,
      ),
      true,
    );
  });
}
