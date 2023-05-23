// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/testing.dart';

import '../../dart_test_infra/data/dart_classes.dart';
import '../../flutter_test_infra/flutter_classes.dart';
import '../../flutter_test_infra/flutter_helpers.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  testWidgets('Leaks in pumpWidget are detected.', (WidgetTester tester) async {
    late Leaks leaks;

    await expectLater(
      () async => await withFlutterLeakTracking(
        () async {
          await tester.pumpWidget(StatelessLeakingWidget());
        },
        tester,
        LeakTrackingTestConfig(
          onLeaks: (foundLeaks) => leaks = foundLeaks,
        ),
      ),
      throwsA(contains('Expected: leak free')),
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 2);

    final notDisposedLeak = leaks.notDisposed.first;
    expect(
      notDisposedLeak.trackedClass,
      contains(InstrumentedClass.library),
    );
    expect(notDisposedLeak.trackedClass, contains('$InstrumentedClass'));

    final notGcedLeak = leaks.notDisposed.first;
    expect(notGcedLeak.trackedClass, contains(InstrumentedClass.library));
    expect(notGcedLeak.trackedClass, contains('$InstrumentedClass'));
  });

  testWidgetsWithLeakTracking('Leak-free code in pumpWidget passes.',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
  });
}
