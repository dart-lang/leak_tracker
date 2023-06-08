// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/shared/_primitives.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'package:test/test.dart';

import '../../test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
void main() {
  tearDown(() => disableLeakTracking());

  test('Not disposed object reported.', () async {
    final leaks = await withLeakTracking(
      () async {
        LeakTrackedClass();
      },
      shouldThrowOnLeaks: false,
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 1);

    final theLeak = leaks.notDisposed.first;
    expect(theLeak.trackedClass, contains(LeakTrackedClass.library));
    expect(theLeak.trackedClass, contains('$LeakTrackedClass'));
  });

  test('Not GCed object reported.', () async {
    late LeakTrackedClass notGCedObject;
    final leaks = await withLeakTracking(
      () async {
        notGCedObject = LeakTrackedClass();
        // Dispose reachable instance.
        notGCedObject.dispose();
      },
      shouldThrowOnLeaks: false,
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 1);

    final theLeak = leaks.notGCed.first;
    expect(theLeak.trackedClass, contains(LeakTrackedClass.library));
    expect(theLeak.trackedClass, contains('$LeakTrackedClass'));
  });

  test('Retaining path cannot be collected in release mode.', () async {
    late LeakTrackedClass notGCedObject;
    Future<void> test() => withLeakTracking(
          () async {
            notGCedObject = LeakTrackedClass();
            // Dispose reachable instance.
            notGCedObject.dispose();
          },
          shouldThrowOnLeaks: false,
          leakDiagnosticConfig: const LeakDiagnosticConfig(
            collectRetainingPathForNonGCed: true,
          ),
        );

    expect(
      () async => await test(),
      throwsA(
        predicate(
          (e) => e is StateError && e.message.contains('--debug'),
        ),
      ),
    );
  });

  test('$isLeakFree succeeds.', () async {
    final leaks = await withLeakTracking(
      () async {},
      shouldThrowOnLeaks: false,
    );

    expect(leaks, isLeakFree);
  });

  test('Stack trace does not start with leak tracker calls.', () async {
    final leaks = await withLeakTracking(
      () async {
        LeakingClass();
      },
      shouldThrowOnLeaks: false,
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectStackTraceOnStart: true,
        collectStackTraceOnDisposal: true,
      ),
    );

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

          expect(line, isNot(contains(leakTrackerStackTraceFragment)));
        }
      }
    }
  });
}
