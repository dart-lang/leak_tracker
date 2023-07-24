// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:test/test.dart';

import '../../test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
void main() {
  setUp(() {
    LeakTrackerGlobalState.maxRequestsForRetainingPath = null;
  });

  tearDown(() => disableLeakTracking());

  for (var numberOfGcCycles in [1, defaultNumberOfGcCycles]) {
    test(
        'Leak tracker respects maxRequestsForRetainingPath, $numberOfGcCycles.',
        () async {
      LeakTrackerGlobalState.maxRequestsForRetainingPath = 2;
      final leaks = await withLeakTracking(
        () async {
          LeakingClass();
          LeakingClass();
          LeakingClass();
        },
        shouldThrowOnLeaks: false,
        leakDiagnosticConfig: const LeakDiagnosticConfig(
          collectRetainingPathForNonGCed: true,
        ),
        numberOfGcCycles: numberOfGcCycles,
      );

      const pathHeader = '  path: >';

      expect(leaks.notGCed, hasLength(3));
      expect(
        () => expect(leaks, isLeakFree),
        throwsA(
          predicate(
            (e) {
              if (e is! TestFailure) {
                throw 'Unexpected exception type: ${e.runtimeType}';
              }
              expect(pathHeader.allMatches(e.message!), hasLength(2));
              return true;
            },
          ),
        ),
      );
    });

    test('Retaining path for not GCed object is reported, $numberOfGcCycles.',
        () async {
      final leaks = await withLeakTracking(
        () async {
          LeakingClass();
        },
        shouldThrowOnLeaks: false,
        leakDiagnosticConfig: const LeakDiagnosticConfig(
          collectRetainingPathForNonGCed: true,
        ),
        numberOfGcCycles: numberOfGcCycles,
      );

      const expectedRetainingPathTails = [
        '/leak_tracker/test/test_infra/data/dart_classes.dart/_notGCedObjects',
        'dart.core/_GrowableList:',
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
}

void _verifyRetainingPath(
  List<String> expectedRetainingPathFragments,
  String actualMessage,
) {
  int? previousIndex;
  for (var item in expectedRetainingPathFragments) {
    final index = actualMessage.indexOf(item);
    if (previousIndex == null) {
      previousIndex = index;
      continue;
    }

    expect(index, greaterThan(previousIndex));
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
