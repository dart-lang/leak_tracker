// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:test/test.dart';

import '../../leak_tracker/test/test_infra/data/dart_classes.dart';

void main() {
  tearDown(LeakTracking.stop);

  for (var numberOfGcCycles in [1, defaultNumberOfGcCycles]) {
    test('Passive leak tracking detects leaks, $numberOfGcCycles.', () async {
      LeakTracking.start(
        resetIfAlreadyStarted: true,
        config: LeakTrackingConfig.passive(
          numberOfGcCycles: numberOfGcCycles,
        ),
      );

      LeakTracking.phase = const PhaseSettings.experimentalNotGCedOn();

      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.ignoreLeaks, false);

      LeakingClass();
      LeakingClass();
      LeakingClass();

      expect(LeakTracking.phase.ignoreLeaks, false);

      await forceGC(fullGcCycles: defaultNumberOfGcCycles);
      final leaks = await LeakTracking.collectLeaks();
      LeakTracking.stop();

      expect(leaks.notGCed, hasLength(3));
      expect(leaks.notDisposed, hasLength(3));
      expect(
        () => expect(leaks, isLeakFree),
        throwsA(isA<TestFailure>()),
      );
    });
  }

  test('Stack trace does not start with leak_tracker calls', () async {
    LeakTracking.start(
      resetIfAlreadyStarted: true,
      config: LeakTrackingConfig.passive(),
    );

    LeakTracking.phase = const PhaseSettings(
      ignoredLeaks: IgnoredLeaks(experimentalNotGCed: IgnoredLeaksSet()),
      leakDiagnosticConfig: LeakDiagnosticConfig(
        collectStackTraceOnDisposal: true,
        collectStackTraceOnStart: true,
      ),
    );

    LeakingClass();

    await forceGC(fullGcCycles: defaultNumberOfGcCycles);
    final leaks = await LeakTracking.collectLeaks();
    LeakTracking.stop();

    expect(leaks.notGCed, hasLength(1));
    expect(leaks.notDisposed, hasLength(1));

    try {
      expect(leaks, isLeakFree);
      fail('Leaks were expected.');
    } catch (error) {
      const traceHeaders = ['start: >', 'disposal: >'];

      final lines = error.toString().split('\n').asMap();

      for (final header in traceHeaders) {
        final headerInexes =
            lines.keys.where((i) => lines[i]!.endsWith(header));
        expect(headerInexes, isNotEmpty);
        for (final i in headerInexes) {
          if (i + 1 >= lines.length) continue;
          final line = lines[i + 1]!;

          const leakTrackerStackTraceFragment = '(package:leak_tracker/';
          expect(line, isNot(contains(leakTrackerStackTraceFragment)));
        }
      }
    }
  });

  for (var numberOfGcCycles in [1, defaultNumberOfGcCycles]) {
    test(
        'leak_tracker respects maxRequestsForRetainingPath, $numberOfGcCycles.',
        () async {
      LeakTracking.start(
        resetIfAlreadyStarted: true,
        config: LeakTrackingConfig.passive(
          numberOfGcCycles: numberOfGcCycles,
          maxRequestsForRetainingPath: 2,
        ),
      );

      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.ignoreLeaks, false);

      LeakTracking.phase = const PhaseSettings(
        ignoredLeaks: IgnoredLeaks(experimentalNotGCed: IgnoredLeaksSet()),
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectRetainingPathForNotGCed: true,
        ),
      );

      LeakingClass();
      LeakingClass();
      LeakingClass();

      expect(LeakTracking.phase.ignoreLeaks, false);

      await forceGC(fullGcCycles: defaultNumberOfGcCycles);
      final leaks = await LeakTracking.collectLeaks();
      LeakTracking.stop();

      const pathHeader = '  path: >';

      expect(leaks.notGCed, hasLength(3));
      expect(
        () => expect(leaks, isLeakFree),
        throwsA(
          predicate(
            (e) {
              if (e is! TestFailure) {
                throw Exception('Unexpected exception type: ${e.runtimeType}');
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
      LeakTracking.start(
        resetIfAlreadyStarted: true,
        config: LeakTrackingConfig.passive(
          numberOfGcCycles: numberOfGcCycles,
          maxRequestsForRetainingPath: 2,
        ),
      );

      LeakTracking.phase = const PhaseSettings(
        ignoredLeaks: IgnoredLeaks(experimentalNotGCed: IgnoredLeaksSet()),
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectRetainingPathForNotGCed: true,
        ),
      );

      LeakingClass();

      const expectedRetainingPathTails = [
        '/leak_tracker/test/test_infra/data/dart_classes.dart/_notGCedObjects',
        'dart.core/_GrowableList:',
        '/leak_tracker/test/test_infra/data/dart_classes.dart/LeakTrackedClass',
      ];

      await forceGC(fullGcCycles: defaultNumberOfGcCycles);
      final leaks = await LeakTracking.collectLeaks();
      LeakTracking.stop();

      expect(leaks.total, 2);
      expect(
        () => expect(leaks, isLeakFree),
        throwsA(
          predicate(
            (e) {
              if (e is! TestFailure) {
                throw Exception('Unexpected exception type: ${e.runtimeType}');
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
      reason: 'There should be only one line break between '
          'items in retaining path.',
    );
    previousIndex = index;
  }
}
