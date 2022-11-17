// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/src/_dispatcher.dart';
import 'package:leak_tracker/src/_object_tracker.dart';

import '../test_infra/generated.mocks.dart';

void main() {
  test('$ObjectTracker consumes Flutter SDK instrumentation.', () {
    final tracker = MockObjectTracker();
    expect(tracker, isNotNull);

    MemoryAllocations.instance
        .addListener((event) => dispatchObjectEvent(event.toMap(), tracker));
  });
}
