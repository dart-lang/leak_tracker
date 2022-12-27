// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

/// The helper lives temporary in this library.
///
/// We will need to move it to shared place,
/// keeping dependency on leak_traker staying in `dev_dependencies`.
Future<void> testWidgetsWithLeakTracking(
  String description,
  Future<void> Function(WidgetTester) callback, {
  StackTraceCollectionConfig stackTraceCollectionConfig =
      const StackTraceCollectionConfig(),
}) async {
  void flutterEventToLeakTracker(ObjectEvent event) =>
      dispatchObjectEvent(event.toMap());
  MemoryAllocations.instance.addListener(flutterEventToLeakTracker);

  try {
    testWidgets(
      description,
      (WidgetTester tester) async {
        final Leaks leaks = await withLeakTracking(
          () async => callback(tester),
          asyncCodeRunner: (DartAsyncCallback action) async =>
              tester.runAsync(action),
          stackTraceCollectionConfig: stackTraceCollectionConfig,
        );
        expect(leaks, isLeakFree);
      },
    );
  } finally {
    MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
  }
}
