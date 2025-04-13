// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/primitives/_gc_counter.dart';
import 'package:test/test.dart';

void main() {
  test('shouldObjectBeGced', () {
    final now = DateTime(2022);
    const gcNow = 1000;
    const timeToDispose = Duration(milliseconds: 100);

    bool shouldBeGced(int disposalGcCount, DateTime disposalTime) =>
        shouldObjectBeGced(
          gcCountAtDisposal: disposalGcCount,
          timeAtDisposal: disposalTime,
          currentGcCount: gcNow,
          currentTime: now,
          disposalTime: timeToDispose,
          numberOfGcCycles: defaultNumberOfGcCycles,
        );

    final forJustGcEd = shouldBeGced(gcNow, now);
    expect(forJustGcEd, isFalse);

    final forNotEnoughTime = shouldBeGced(gcNow - 100, now);
    expect(forNotEnoughTime, isFalse);

    final forNotEnoughGc =
        shouldBeGced(gcNow, now.add(const Duration(days: -1)));
    expect(forNotEnoughGc, isFalse);

    final forEnoughTimeAndGc = shouldBeGced(
      gcNow - defaultNumberOfGcCycles,
      now.subtract(timeToDispose),
    );
    expect(forEnoughTimeAndGc, isTrue);
  });
}
