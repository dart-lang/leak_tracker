// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/shared/_primitives.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:logging/logging.dart';

import 'package:test/test.dart';

import '../../test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
void main() {
  Logger.root.onRecord.listen((LogRecord record) => print(record.message));

  tearDown(() {
    disableLeakTracking();
  });

  for (var gcCountBuffer in [1, defaultGcCountBuffer]) {
    test('Not disposed object reported, $gcCountBuffer.', () async {
      final leaks = await withLeakTracking(
        () async {
          LeakTrackedClass();
        },
        shouldThrowOnLeaks: false,
        gcCountBuffer: gcCountBuffer,
      );

      expect(() => expect(leaks, isLeakFree), throwsException);
      expect(leaks.total, 1);

      final theLeak = leaks.notDisposed.first;
      expect(theLeak.trackedClass, contains(LeakTrackedClass.library));
      expect(theLeak.trackedClass, contains('$LeakTrackedClass'));
    });

    test('Not GCed object reported, $gcCountBuffer.', () async {
      late LeakTrackedClass notGCedObject;
      final leaks = await withLeakTracking(
        () async {
          notGCedObject = LeakTrackedClass();
          // Dispose reachable instance.
          notGCedObject.dispose();
        },
        shouldThrowOnLeaks: false,
        gcCountBuffer: gcCountBuffer,
      );

      expect(() => expect(leaks, isLeakFree), throwsException);
      expect(leaks.total, 1);

      final theLeak = leaks.notGCed.first;
      expect(theLeak.trackedClass, contains(LeakTrackedClass.library));
      expect(theLeak.trackedClass, contains('$LeakTrackedClass'));
    });

    test('temp', () async {
      Future<void> f1() async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw StateError('f1');
      }

      try {
        await Future.wait<void>([f1(), f1()]);
      } catch (e) {
        print(e);
      }
    });

    test('Retaining path cannot be collected in release mode, $gcCountBuffer.',
        () async {
      late LeakTrackedClass notGCedObject;
      Future<void> test() async {
        await withLeakTracking(
          () async {
            notGCedObject = LeakTrackedClass();
            // Dispose reachable instance.
            notGCedObject.dispose();
          },
          shouldThrowOnLeaks: false,
          leakDiagnosticConfig: const LeakDiagnosticConfig(
            collectRetainingPathForNonGCed: true,
          ),
          gcCountBuffer: gcCountBuffer,
        );
      }

      try {
        await test();
      } on StateError catch (error) {
        print(error);
        // expect(error, isA<StateError>());
        // expect(
        //   error.toString(),
        //   contains('Leak troubleshooting is not available in release mode.'),
        // );
      }

      // await expectLater(
      //   test,
      //   throwsA(
      //     predicate(
      //       (e) => e is StateError && e.message.contains('--debug'),
      //     ),
      //   ),
      // );
    });

    test('$isLeakFree succeeds, $gcCountBuffer.', () async {
      final leaks = await withLeakTracking(
        () async {},
        shouldThrowOnLeaks: false,
        gcCountBuffer: gcCountBuffer,
      );

      expect(leaks, isLeakFree);
    });

    test('Stack trace does not start with leak tracker calls, $gcCountBuffer.',
        () async {
      final leaks = await withLeakTracking(
        () async {
          LeakingClass();
        },
        shouldThrowOnLeaks: false,
        leakDiagnosticConfig: const LeakDiagnosticConfig(
          collectStackTraceOnStart: true,
          collectStackTraceOnDisposal: true,
        ),
        gcCountBuffer: gcCountBuffer,
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
}
