// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:leak_tracker/src/leak_tracking/_gc_counter.dart';
import 'package:leak_tracker/src/leak_tracking/orchestration.dart';
import 'package:test/test.dart';

void main() {
  test('$withLeakTracking does not fail after exception.', () async {
    const exception = 'some exception';
    try {
      await withLeakTracking(
        () => throw exception,
        shouldThrowOnLeaks: false,
      );
    } catch (e) {
      expect(e, exception);
    }

    await withLeakTracking(() async {});
  });

  group('forceGC', () {
    test('forces gc', () async {
      Object? myObject = <int>[1, 2, 3, 4, 5];
      final ref = WeakReference(myObject);
      myObject = null;

      await forceGC();

      expect(ref.target, null);
    });

    test('forces gc', () async {
      Object? myObject = <int>[1, 2, 3, 4, 5];
      final ref = WeakReference(myObject);
      myObject = null;

      await forceGC();

      expect(ref.target, null);
    });

    test('times out', () async {
      await expectLater(
        forceGC(timeout: Duration.zero),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
