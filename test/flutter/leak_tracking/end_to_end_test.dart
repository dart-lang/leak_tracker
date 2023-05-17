// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../../dart_test_infra/data/dart_classes.dart';
import '../../flutter_test_infra/flutter_classes.dart';
import '../../flutter_test_infra/flutter_helpers.dart';

/// Normally 300 milliseconds are ok, but sometimes test environment is slow.
const _gcTimeout = Duration(milliseconds: 10000);

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  testWidgets('Leaks in pumpWidget are detected.', (WidgetTester tester) async {
    late Leaks leaks;

    expect(
      () async => await withFlutterLeakTracking(
        () async {
          await tester.pumpWidget(StatelessLeakingWidget());
        },
        tester: tester,
        leaksObtainer: (foundLeaks) => leaks = foundLeaks,
      ),
      throwsA(
        predicate((e) {
          expect(e.toString(), contains('Expected: leak free'));
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

          return true;
        }),
      ),
    );
  });

  test('Not disposed members are cought.', () async {
    late Leaks leaks;

    expect(
      () async => await withFlutterLeakTracking(
        () async {
          // ignore: unused_local_variable
          Object? notDisposer = ValueNotifierNotDisposer();
          notDisposer = null;
        },
        tester: null,
        leaksObtainer: (foundLeaks) => leaks = foundLeaks,
      ),
      throwsA(
        predicate((e) {
          expect(e.toString(), contains('Expected: leak free'));

          expect(() => expect(leaks, isLeakFree), throwsException);
          expect(leaks.total, 1);

          final theLeak = leaks.notDisposed.first;
          expect(theLeak.trackedClass, contains('foundation.dart'));
          expect(theLeak.trackedClass, contains('ValueNotifier<'));

          return true;
        }),
      ),
    );
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
