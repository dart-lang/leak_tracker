// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../test_infra/data/dart_classes.dart';
import '../test_infra/data/flutter_classes.dart';
import '../test_infra/flutter_helpers.dart';

const _gcTimeout = Duration(milliseconds: 1000);

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  testWidgets('Leaks in pumpWidget are detected.', (WidgetTester tester) async {
    expect(
      () async => await withFlutterLeakTracking(tester, (tester) async {
        await tester.pumpWidget(StatelessLeakingWidget());
      }),
      throwsA(
        predicate((e) {
          if (e is! MemoryLeaksDetectedError) {
            throw 'Wrong exception type: ${e.runtimeType}';
          }

          expect(() => expect(e.leaks, isLeakFree), throwsException);
          expect(e.leaks.total, 2);

          final notDisposedLeak = e.leaks.notDisposed.first;
          expect(notDisposedLeak.trackedClass,
              contains(InstrumentedClass.library));
          expect(notDisposedLeak.trackedClass, contains('$InstrumentedClass'));

          final notGcedLeak = e.leaks.notDisposed.first;
          expect(notGcedLeak.trackedClass, contains(InstrumentedClass.library));
          expect(notGcedLeak.trackedClass, contains('$InstrumentedClass'));

          return true;
        }),
      ),
    );
  });

  test('Not disposed members are cought.', () async {
    expect(
      () async => await withFlutterLeakTracking(tester, (tester) async {
        await tester.pumpWidget(StatelessLeakingWidget());
      }),
      throwsA(
        predicate((e) {
          if (e is! MemoryLeaksDetectedError) {
            throw 'Wrong exception type: ${e.runtimeType}';
          }

          expect(() => expect(e.leaks, isLeakFree), throwsException);
          expect(e.leaks.total, 2);

          final notDisposedLeak = e.leaks.notDisposed.first;
          expect(notDisposedLeak.trackedClass,
              contains(InstrumentedClass.library));
          expect(notDisposedLeak.trackedClass, contains('$InstrumentedClass'));

          final notGcedLeak = e.leaks.notDisposed.first;
          expect(notGcedLeak.trackedClass, contains(InstrumentedClass.library));
          expect(notGcedLeak.trackedClass, contains('$InstrumentedClass'));

          return true;
        }),
      ),
    );

    final leaks = await withLeakTracking(
      () async {
        // ignore: unused_local_variable
        Object? notDisposer = ValueNotifierNotDisposer();
        notDisposer = null;
      },
      timeoutForFinalGarbageCollection: _gcTimeout,
      shouldThrowOnLeaks: false,
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 1);

    final theLeak = leaks.notDisposed.first;
    expect(theLeak.trackedClass, contains('foundation.dart'));
    expect(theLeak.trackedClass, contains('ValueNotifier<'));
  });

  testWidgets('Leak-free code in pumpWidget passes.',
      (WidgetTester tester) async {
    await withLeakTracking(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      },
      timeoutForFinalGarbageCollection: _gcTimeout,
      asyncCodeRunner: (action) async => tester.runAsync(action),
    );
  });
}
