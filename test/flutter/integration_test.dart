// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/testing.dart';

import '../test_infra/data/dart_classes.dart';
import '../test_infra/data/flutter_classes.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  testWidgets('Leaks in pumpWidget are detected.', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final leaks = await withLeakTracking(
        () async {
          await tester.pumpWidget(StatelessLeakingWidget());
        },
        throwOnLeaks: false,
      );

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
