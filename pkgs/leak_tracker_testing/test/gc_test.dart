// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:test/test.dart';

void main() {
  test('forceGC forces gc', () async {
    Object? myObject = <int>[1, 2, 3, 4, 5];
    final ref = WeakReference(myObject);
    myObject = null;

    await forceGC();

    expect(ref.target, null);
  });

  test('forceGC times out', () async {
    await expectLater(
      forceGC(timeout: Duration.zero),
      throwsA(isA<TimeoutException>()),
    );
  });
}
