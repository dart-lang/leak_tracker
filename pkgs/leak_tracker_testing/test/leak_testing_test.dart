// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/leak_tracking/primitives/model.dart';
import 'package:leak_tracker_testing/src/leak_testing.dart';
import 'package:test/test.dart';

void main() {
  group('$LeakTesting', () {
    test('debug info preserves other settings', () {
      final settings = LeakTesting.settings
          .withIgnored(notDisposed: {'MyClass': 1})
          .withIgnored(createdByTestHelpers: true)
          .withIgnored()
          .withCreationStackTrace()
          .withDisposalStackTrace()
          .withRetainingPath();

      expect(
        settings.leakDiagnosticConfig.collectRetainingPathForNotGCed,
        true,
      );
      expect(
        settings.leakDiagnosticConfig.collectStackTraceOnDisposal,
        true,
      );
      expect(
        settings.leakDiagnosticConfig.collectStackTraceOnStart,
        true,
      );
      expect(
        settings.ignoredLeaks.notDisposed.byClass.keys.firstOrNull,
        'MyClass',
      );
      expect(
        settings.ignoredLeaks.createdByTestHelpers,
        true,
      );
    });

    group('withTracked', () {
      test('not provided args do not affect the instance, tracked', () {
        final settings = LeakTesting.settings.withTrackedAll().withIgnored(
          allNotDisposed: true,
          allNotGCed: true,
          createdByTestHelpers: true,
          testHelperExceptions: [RegExp('my_test.dart')],
        );

        expect(settings.ignoredLeaks.notDisposed.ignoreAll, true);
        expect(settings.ignoredLeaks.experimentalNotGCed.ignoreAll, true);

        final tracked = settings.withTracked(
            allNotDisposed: true, experimentalAllNotGCed: true);

        expect(tracked.ignoredLeaks.notDisposed.ignoreAll, false);
        expect(tracked.ignoredLeaks.experimentalNotGCed.ignoreAll, false);
        expect(tracked.ignoredLeaks.createdByTestHelpers, true);
        expect(tracked.ignoredLeaks.testHelperExceptions, hasLength(1));
      });
    });

    group('withIgnored and withTracked', () {
      test('not provided args do not affect the instance, tracked', () {
        final settings = LeakTesting.settings
            .withTrackedAll()
            .withTracked(experimentalAllNotGCed: true);

        expect(settings.ignore, false);
        expect(settings.ignoredLeaks.notDisposed.ignoreAll, false);
        expect(settings.ignoredLeaks.notDisposed.byClass, <String, int?>{});
        expect(settings.ignoredLeaks.experimentalNotGCed.ignoreAll, false);
        expect(settings.ignoredLeaks.experimentalNotGCed.byClass,
            <String, int?>{});

        expect(settings.withIgnored(), settings);
        expect(settings.withTracked(), settings);

        final withPath = settings
            .withRetainingPath()
            .copyWith(leakDiagnosticConfig: const LeakDiagnosticConfig());
        expect(withPath, settings);
      });

      test('not provided args do not affect the instance, ignored', () {
        final settings = LeakTesting.settings.withIgnoredAll().withIgnored(
          allNotDisposed: true,
          allNotGCed: true,
          classes: ['MyClass'],
          testHelperExceptions: [RegExp('my_test.dart')],
        );

        expect(settings.ignore, true);
        expect(settings.ignoredLeaks.notDisposed.ignoreAll, true);
        expect(settings.ignoredLeaks.notDisposed.byClass, hasLength(1));
        expect(settings.ignoredLeaks.experimentalNotGCed.ignoreAll, true);
        expect(settings.ignoredLeaks.experimentalNotGCed.byClass, hasLength(1));

        expect(settings.withIgnored(), settings);
        expect(settings.withTracked(), settings);

        final withPath = settings
            .withRetainingPath()
            .copyWith(leakDiagnosticConfig: const LeakDiagnosticConfig());
        expect(withPath, settings);
      });
    });

    group('equals', () {
      test('trivial', () {
        final settings1 = LeakTesting.settings.copyWith();
        final settings2 = LeakTesting.settings.copyWith();

        expect(settings1 == settings2, true);
      });

      test('customized equal', () {
        final settings1 = LeakTesting.settings.copyWith(
          leakDiagnosticConfig: const LeakDiagnosticConfig(),
          ignoredLeaks: const IgnoredLeaks(),
        );
        final settings2 = LeakTesting.settings.copyWith(
          leakDiagnosticConfig: const LeakDiagnosticConfig(),
          ignoredLeaks: const IgnoredLeaks(),
        );

        expect(settings1 == settings2, true);
      });

      test('different', () {
        const list1 = IgnoredLeaks(
          notDisposed: IgnoredLeaksSet(byClass: {'MyClass': null}),
          experimentalNotGCed: IgnoredLeaksSet(byClass: {'MyClass': 1}),
        );
        const list2 = IgnoredLeaks(
          notDisposed: IgnoredLeaksSet(byClass: {'MyClass': 1}),
          experimentalNotGCed: IgnoredLeaksSet(byClass: {'MyClass': 1}),
        );
        expect(list1 == list2, false);
      });
    });
  });
}
