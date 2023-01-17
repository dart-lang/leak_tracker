// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helpers in this library are candidates to become separate
// public package under https://github.com/flutter.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

/// Wrapper for [withLeakTracking] with Flutter specific functionality.
///
/// 1. Listens to [MemoryAllocations] events.
/// 2. Uses `tester.runAsync` for leak detection if [tester] is provided.
Future<void> withFlutterLeakTracking(
  DartAsyncCallback callback, {
  required WidgetTester? tester,
  StackTraceCollectionConfig stackTraceCollectionConfig =
      const StackTraceCollectionConfig(),
  Duration? timeoutForFinalGarbageCollection,
  void Function(Leaks foundLeaks)? leaksObtainer,
}) async {
  void flutterEventToLeakTracker(ObjectEvent event) =>
      dispatchObjectEvent(event.toMap());
  MemoryAllocations.instance.addListener(flutterEventToLeakTracker);

  final asyncCodeRunner = tester == null
      ? (DartAsyncCallback action) async => action()
      : (DartAsyncCallback action) async => tester.runAsync(action);

  try {
    final Leaks leaks = await withLeakTracking(
      () async => callback(),
      asyncCodeRunner: asyncCodeRunner,
      stackTraceCollectionConfig: stackTraceCollectionConfig,
      shouldThrowOnLeaks: false,
      timeoutForFinalGarbageCollection: timeoutForFinalGarbageCollection,
    );
    if (leaksObtainer != null) {
      leaksObtainer(leaks);
    }
    expect(leaks, isLeakFree);
  } finally {
    MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
  }
}
