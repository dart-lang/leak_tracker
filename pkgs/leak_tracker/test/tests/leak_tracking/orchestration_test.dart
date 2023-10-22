// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:leak_tracker/src/leak_tracking/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('forceGC', () {
    test('forces gc', () async {
      Object? myObject = <int>[1, 2, 3, 4, 5];
      final ref = WeakReference(myObject);
      myObject = null;

      await forceGC();

      expect(ref.target, null);
    });

    test('times out', () async {
      await expectLater(
        () async => forceGC(timeout: Duration.zero),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('takes reasonable time', () async {
      const rounds = 100;
      final sw = Stopwatch()..start();

      for (var _ in Iterable<void>.generate(rounds)) {
        await forceGC();
      }

      final durationPerRound = sw.elapsed ~/ rounds;
      expect(durationPerRound.inMilliseconds, lessThan(200));
    });
  });
}
