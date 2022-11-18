// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/src/_dispatcher.dart';
import 'package:leak_tracker/src/_object_tracker.dart';
import 'package:leak_tracker/src/leak_tracker_model.dart';

import '../test_infra/generated.mocks.dart';

void main() {
  test('$ObjectTracker consumes Flutter SDK instrumentation.', () {
    final tracker = MockObjectTracker();
    //when(tracker.startTracking(object, context: context, trackedClass: trackedClass))

    MemoryAllocations.instance
        .addListener((event) => dispatchObjectEvent(event.toMap(), tracker));
  });
}

class MockObjectTracker extends ObjectTracker {
  MockObjectTracker() : super(LeakTrackingConfiguration());

  @override
  void startTracking(
    Object object, {
    required Map<String, dynamic>? context,
    required String trackedClass,
  }) {}
}
