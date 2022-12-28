// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';

import 'package:test/test.dart';

import '../test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  tearDown(() => disableLeakTracking());

  test('Not disposed object reported.', () async {
    final leaks = await withLeakTracking(
      () async {
        InstrumentedClass();
      },
      shouldThrowOnLeaks: false,
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 1);

    final theLeak = leaks.notDisposed.first;
    expect(theLeak.trackedClass, contains(InstrumentedClass.library));
    expect(theLeak.trackedClass, contains('$InstrumentedClass'));
  });

  test('Not GCed object reported.', () async {
    late InstrumentedClass notGCedObject;
    final leaks = await withLeakTracking(
      () async {
        notGCedObject = InstrumentedClass();
        // Dispose reachable instance.
        notGCedObject.dispose();
      },
      shouldThrowOnLeaks: false,
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 1);

    final theLeak = leaks.notGCed.first;
    expect(theLeak.trackedClass, contains(InstrumentedClass.library));
    expect(theLeak.trackedClass, contains('$InstrumentedClass'));
  });

  test('$isLeakFree succeeds.', () async {
    final leaks = await withLeakTracking(
      () async {},
      shouldThrowOnLeaks: false,
    );

    expect(leaks, isLeakFree);
  });
}
