// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/leak_detection/orchestration.dart';
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
}
