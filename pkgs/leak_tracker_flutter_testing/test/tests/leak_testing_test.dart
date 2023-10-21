// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/src/leak_tracking/_primitives/model.dart';
import 'package:leak_tracker_flutter_testing/src/leak_testing.dart';

void main() {
  group('$LeakTesting', () {
    group('equals', () {
      test('trivial', () {
        final settings1 = LeakTesting.settings.copyWith();
        final settings2 = LeakTesting.settings.copyWith();

        expect(settings1 == settings2, true);
      });

      test('customized equal', () {
        void onLeaks(_) {}

        final settings1 = LeakTesting.settings.copyWith(
          onLeaks: onLeaks,
          leakDiagnosticConfig: const LeakDiagnosticConfig(),
          ignoredLeaks: const IgnoredLeaks(),
        );
        final settings2 = LeakTesting.settings.copyWith(
          onLeaks: onLeaks,
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
