// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../test_infra/data/dart_classes.dart';
import '../test_infra/data/flutter_classes.dart';

void _flutterEventListener(ObjectEvent event) =>
    dispatchObjectEvent(event.toMap());

const _gcTimeout = Duration(milliseconds: 1000);

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  setUpAll(() {
    MemoryAllocations.instance.addListener(_flutterEventListener);
  });

  tearDownAll(() {
    MemoryAllocations.instance.removeListener(_flutterEventListener);
  });

  testWidgets('Leaks in pumpWidget are detected.', (WidgetTester tester) async {
    final leaks = await withLeakTracking(
      () async {
        await tester.pumpWidget(StatelessLeakingWidget());
      },
      timeoutForFinalGarbageCollection: _gcTimeout,
      asyncCodeRunner: (action) async => tester.runAsync(action),
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 2);

    final notDisposedLeak = leaks.notDisposed.first;
    expect(notDisposedLeak.trackedClass, contains(InstrumentedClass.library));
    expect(notDisposedLeak.trackedClass, contains('$InstrumentedClass'));

    final notGcedLeak = leaks.notDisposed.first;
    expect(notGcedLeak.trackedClass, contains(InstrumentedClass.library));
    expect(notGcedLeak.trackedClass, contains('$InstrumentedClass'));
  });

  testWidgets('Leak-free code in pumpWidget passes.',
      (WidgetTester tester) async {
    await withLeakTracking(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      },
      timeoutForFinalGarbageCollection: _gcTimeout,
      asyncCodeRunner: (action) async => tester.runAsync(action),
      throwOnLeaks: true,
    );
  });

  test('Not disposed member is cought.', () async {
    final leaks = await withLeakTracking(
      () async {
        // ignore: unused_local_variable
        Object? notDisposer = ValueNotifierNotDisposer();
        notDisposer = null;
      },
      timeoutForFinalGarbageCollection: _gcTimeout,
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 1);

    final theLeak = leaks.notDisposed.first;
    expect(theLeak.trackedClass, contains('foundation.dart'));
    expect(theLeak.trackedClass, contains('ValueNotifier<'));
  });
}
