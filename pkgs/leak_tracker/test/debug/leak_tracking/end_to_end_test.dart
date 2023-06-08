// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:test/test.dart';

import '../../test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
void main() {
  tearDown(() => disableLeakTracking());

  test('Retaining path for not GCed object is reported.', () async {
    final leaks = await withLeakTracking(
      () async {
        LeakingClass();
      },
      shouldThrowOnLeaks: false,
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectRetainingPathForNonGCed: true,
      ),
    );

    const expectedRetainingPathTails = [
      '/leak_tracker/test/test_infra/data/dart_classes.dart/_notGCedObjects',
      'dart.core/_GrowableList:0',
      '/leak_tracker/test/test_infra/data/dart_classes.dart/LeakTrackedClass',
    ];

    expect(leaks.total, 2);
    expect(
      () => expect(leaks, isLeakFree),
      throwsA(
        predicate(
          (e) {
            if (e is! TestFailure) {
              throw 'Unexpected exception type: ${e.runtimeType}';
            }
            _verifyRetainingPath(expectedRetainingPathTails, e.message!);
            return true;
          },
        ),
      ),
    );

    final theLeak = leaks.notGCed.first;
    expect(theLeak.trackedClass, contains(LeakTrackedClass.library));
    expect(theLeak.trackedClass, contains('$LeakTrackedClass'));
  });
}

void _verifyRetainingPath(
  List<String> expectedRetainingPathTails,
  String actualMessage,
) {
  int? previousIndex;
  for (var item in expectedRetainingPathTails) {
    final index = actualMessage.indexOf('$item\n');
    if (previousIndex == null) {
      previousIndex = index;
      continue;
    }

    expect(index > previousIndex, true);
    final stringBetweenItems = actualMessage.substring(previousIndex, index);
    expect(
      RegExp('^').allMatches(stringBetweenItems).length,
      1,
      reason:
          'There should be only one line break between items in retaining path.',
    );
    previousIndex = index;
  }
}
