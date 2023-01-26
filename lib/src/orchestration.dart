// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:clock/clock.dart';

import '_gc_counter.dart';
import 'leak_tracker.dart';
import 'leak_tracker_model.dart';
import 'shared_model.dart';

/// Asynchronous callback.
///
/// The prefix `Dart` is used to avoid conflict with Flutter's [AsyncCallback].
typedef DartAsyncCallback = Future<void> Function();

typedef AsyncCodeRunner = Future<void> Function(DartAsyncCallback);

class MemoryLeaksDetectedError extends StateError {
  MemoryLeaksDetectedError(this.leaks) : super('Leaks detected.');
  final Leaks leaks;
}

/// Tests the functionality with leak tracking.
///
/// Wrap code inside your test with this method in order to catch memory
/// leaks.
///
/// The methods will fail in two cases:
/// 1. Instrumented objects are garbage collected without being disposed.
/// 2. Instrumented objects are disposed, but not garbage collected.
///
/// See [README.md](https://github.com/dart-lang/leak_tracker/blob/main/README.md)
/// for more details.
///
/// If you test Flutter widgets, connect their instrumentation to the leak
/// tracker:
/// ```
/// void flutterEventListener(ObjectEvent event) => dispatchObjectEvent(event.toMap());
///
/// setUpAll(() {
///   MemoryAllocations.instance.addListener(flutterEventListener);
/// });
///
/// tearDownAll(() {
///   MemoryAllocations.instance.removeListener(flutterEventListener);
/// });
/// ```
///
/// If you use [withLeakTracking] inside [testWidget], pass [tester.runAsync]
/// as [asyncCodeRunner] to run asynchronous leak detection after the
/// test code execution:
///
/// ```
/// testWidgets('...', (WidgetTester tester) async {
///   await withLeakTracking(
///     () async {
///       ...
///     },
///     asyncCodeRunner: (action) async => tester.runAsync(action),
///   );
/// });
/// ```
Future<Leaks> withLeakTracking(
  DartAsyncCallback callback, {
  bool shouldThrowOnLeaks = true,
  Duration? timeoutForFinalGarbageCollection,
  StackTraceCollectionConfig stackTraceCollectionConfig =
      const StackTraceCollectionConfig(),
  AsyncCodeRunner? asyncCodeRunner,
}) async {
  enableLeakTracking(
    resetIfAlreadyEnabled: true,
    config: LeakTrackingConfiguration.passive(
      stackTraceCollectionConfig: stackTraceCollectionConfig,
    ),
  );

  try {
    await callback();

    asyncCodeRunner ??= (action) => action();
    await asyncCodeRunner(
      () async => await _forceGC(
        gcCycles: gcCountBuffer,
        timeout: timeoutForFinalGarbageCollection,
      ),
    );

    final leaks = collectLeaks();

    if (leaks.total > 0 && shouldThrowOnLeaks) {
      // `expect` should not be used here, because, when the method is used
      // from Flutter, the packages `test` and `flutter_test` conflict.
      throw MemoryLeaksDetectedError(leaks);
    }

    return leaks;
  } finally {
    disableLeakTracking();
  }
}

/// Forces garbage collection by aggressive memory allocation.
Future<void> _forceGC({required int gcCycles, Duration? timeout}) async {
  final start = clock.now();
  final barrier = reachabilityBarrier;

  final _storage = <List<DateTime>>[];

  void allocateMemory() {
    _storage.add(Iterable.generate(10000, (_) => DateTime.now()).toList());
    if (_storage.length > 100) _storage.removeAt(0);
  }

  while (reachabilityBarrier < barrier + gcCycles) {
    if (timeout != null && clock.now().difference(start) > timeout) {
      throw TimeoutException('forceGC timed out', timeout);
    }
    await Future.delayed(const Duration());
    allocateMemory();
  }
}
