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
    });

    group('withTracked', () {
      test('not provided args do not affect the instance, tracked', () {
        final settings = LeakTesting.settings.withTrackedAll().withIgnored(
              allNotDisposed: true,
              allNotGCed: true,
            );

        expect(settings.ignoredLeaks.notDisposed.ignoreAll, true);
        expect(settings.ignoredLeaks.notGCed.ignoreAll, true);

        final tracked =
            settings.withTracked(allNotDisposed: true, allNotGCed: true);

        expect(tracked.ignoredLeaks.notDisposed.ignoreAll, false);
        expect(tracked.ignoredLeaks.notGCed.ignoreAll, false);
      });
    });

    group('withIgnored and withTracked', () {
      test('not provided args do not affect the instance, tracked', () {
        final settings = LeakTesting.settings.withTrackedAll();

        expect(settings.ignore, false);
        expect(settings.ignoredLeaks.notDisposed.ignoreAll, false);
        expect(settings.ignoredLeaks.notDisposed.byClass, <String, int?>{});
        expect(settings.ignoredLeaks.notGCed.ignoreAll, false);
        expect(settings.ignoredLeaks.notGCed.byClass, <String, int?>{});

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
        );

        expect(settings.ignore, true);
        expect(settings.ignoredLeaks.notDisposed.ignoreAll, true);
        expect(settings.ignoredLeaks.notDisposed.byClass, hasLength(1));
        expect(settings.ignoredLeaks.notGCed.ignoreAll, true);
        expect(settings.ignoredLeaks.notGCed.byClass, hasLength(1));

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
          notGCed: IgnoredLeaksSet(byClass: {'MyClass': 1}),
        );
        const list2 = IgnoredLeaks(
          notDisposed: IgnoredLeaksSet(byClass: {'MyClass': 1}),
          notGCed: IgnoredLeaksSet(byClass: {'MyClass': 1}),
        );
        expect(list1 == list2, false);
      });
    });
  });
}
