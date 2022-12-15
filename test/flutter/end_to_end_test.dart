// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../test_infra/data/dart_classes.dart';
import '../test_infra/data/flutter_classes.dart';

void _flutterEventListener(ObjectEvent event) =>
    dispatchObjectEvent(event.toMap());

const _gcTimeout = Duration(milliseconds: 500);

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
    await tester.runAsync(() async {
      final leaks = await withLeakTracking(
        () async {
          await tester.pumpWidget(StatelessLeakingWidget());
        },
        throwOnLeaks: false,
        timeoutForFinalGarbageCollection: _gcTimeout,
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

  test('Not disposed member is cought.', () async {
    final leaks = await withLeakTracking(
      () async {
        // ignore: unused_local_variable
        Object? notDisposer = ValueNotifierNotDisposer();
        notDisposer = null;
      },
      throwOnLeaks: false,
      timeoutForFinalGarbageCollection: _gcTimeout,
    );

    expect(leaks.total, 1);

    final theLeak = leaks.notDisposed.first;
    expect(theLeak.trackedClass, contains('foundation.dart'));
    expect(theLeak.trackedClass, contains('ValueNotifier<'));
  });

  // This test will start failing and should be deleted after fix of
  // https://github.com/flutter/flutter/issues/117063
  test('Not disposed ValueNotifier in OverlayEntry is cought.', () async {
    final leaks = await withLeakTracking(
      () async {
        // ignore: unused_local_variable
        Object? notDisposer = OverlayEntry(builder: (_) => const Text('hello'));
        notDisposer = null;
      },
      throwOnLeaks: false,
      timeoutForFinalGarbageCollection: _gcTimeout,
    );

    expect(leaks.total, 1);

    final theLeak = leaks.notDisposed.first;
    expect(theLeak.trackedClass, contains('foundation.dart'));
    expect(theLeak.trackedClass, contains('ValueNotifier<'));
  });
}
