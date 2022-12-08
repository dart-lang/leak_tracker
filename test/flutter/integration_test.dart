// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/_gc_counter.dart';

import '../test_infra/data/dart_classes.dart';
import '../test_infra/data/flutter_classes.dart';
import '../test_infra/helpers/gc.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  tearDown(() => disableLeakTracking());

  testWidgets('Leaks in pumpWidget are detected.', (WidgetTester tester) async {
    await tester.runAsync(() async {
      Future<void> _runApp() async {
        enableLeakTracking(
          config: LeakTrackingConfiguration.minimal(),
        );

        await tester.pumpWidget(StatelessLeakingWidget());
      }

      await _runApp();

      await forceGC(gcCycles: gcCountBuffer);
      final summary = checkLeaks();

      expect(summary.total, 2);
      expect(summary.totals[LeakType.notDisposed], 1);
      expect(summary.totals[LeakType.notGCed], 1);

      final leaks = collectLeaks();
      expect(leaks.total, 2);

      final notDisposedLeak = leaks.notDisposed.first;
      expect(notDisposedLeak.trackedClass, contains(InstrumentedClass.library));
      expect(notDisposedLeak.trackedClass, contains('$InstrumentedClass'));

      final notGcedLeak = leaks.notDisposed.first;
      expect(notGcedLeak.trackedClass, contains(InstrumentedClass.library));
      expect(notGcedLeak.trackedClass, contains('$InstrumentedClass'));
    });
  });
}
