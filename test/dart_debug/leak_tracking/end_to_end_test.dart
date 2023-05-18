// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/testing.dart';
import 'package:test/test.dart';

import '../../dart_test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  tearDown(() => disableLeakTracking());

  test('Retaining path is reported in debug mode.', () async {
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
}
