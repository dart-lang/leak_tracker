// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/shared/_util.dart';
import 'package:test/test.dart';

void main() {
  test('mapEquals', () {
    final Map<int, int> mapA = <int, int>{1: 1, 2: 2, 3: 3};
    final Map<int, int> mapB = <int, int>{1: 1, 2: 2, 3: 3};
    final Map<int, int> mapC = <int, int>{1: 1, 2: 2};
    final Map<int, int> mapD = <int, int>{3: 3, 2: 2, 1: 1};
    final Map<int, int> mapE = <int, int>{3: 1, 2: 2, 1: 3};

    expect(mapEquals<void, void>(null, null), isTrue);
    expect(mapEquals(mapA, null), isFalse);
    expect(mapEquals(null, mapB), isFalse);
    expect(mapEquals(mapA, mapA), isTrue);
    expect(mapEquals(mapA, mapB), isTrue);
    expect(mapEquals(mapA, mapC), isFalse);
    expect(mapEquals(mapA, mapD), isTrue);
    expect(mapEquals(mapA, mapE), isFalse);
  });
}
