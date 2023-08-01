// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:test/test.dart';

import '../test_infra/data/dart_classes.dart';

void main() {
  tearDown(() => LeakTracking.stop());

  for (var numberOfGcCycles in [1, defaultNumberOfGcCycles]) {
    test('Passive leak tracking detects leaks, $numberOfGcCycles.', () async {
      LeakTracking.start(
        resetIfAlreadyStarted: true,
        config: LeakTrackingConfig.passive(
          numberOfGcCycles: numberOfGcCycles,
        ),
      );

      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.isPaused, false);

      LeakingClass();
      LeakingClass();
      LeakingClass();

      expect(LeakTracking.phase.isPaused, false);

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

  test('Stack trace does not start with leak tracker calls', () async {
    LeakTracking.start(
      resetIfAlreadyStarted: true,
      config: LeakTrackingConfig.passive(),
    );

    LeakTracking.phase = const PhaseSettings(
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
}
