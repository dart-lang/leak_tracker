// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:memory_usage/memory_usage.dart';
import 'package:test/test.dart';

void main() {
  test('$MemoryUsageEvent initial', () {
    final event =
        MemoryUsageEvent(rss: 100, delta: null, previousEventTime: null);

    expect(event.delta, null);
    expect(event.period, null);
    expect(event.rss, 100);
  });

  test('$MemoryUsageEvent delta', () {
    final event = MemoryUsageEvent(
      rss: 200,
      delta: 100,
      previousEventTime: DateTime(2022),
      timestamp: DateTime(2023),
    );

    expect(event.delta, 100);
    expect(event.period, const Duration(days: 365));
    expect(event.rss, 200);
  });
}
