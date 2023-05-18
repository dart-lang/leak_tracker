// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:test/test.dart';

void main() {
  test('No retaining path in release mode.', () async {
    expect(
      () => LeakDiagnosticConfig(collectRetainingPathForNonGCed: true),
      throwsA(AssertionError),
    );
  });
}
