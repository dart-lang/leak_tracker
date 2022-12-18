// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:clock/clock.dart';
import 'package:matcher/matcher.dart';

import '_gc_counter.dart';
import 'leak_tracker.dart';
import 'leak_tracker_model.dart';
import 'shared_model.dart';

class MemoryLeaksDetectedError extends StateError {
  MemoryLeaksDetectedError(this.leaks) : super('Leaks detected.');

  final Leaks leaks;
}

/// Tests the functionality with leak tracking.
///
/// If you use `withLeakTracking` inside `testWidget`, connect Flutter
/// objects and use `tester.runAsync`:
///
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
///
/// testWidgets('...', (WidgetTester tester) async {
///   await tester.runAsync(() async {
///     await withLeakTracking(() async {
///       ...
///     });
///   });
/// });
/// ```
Future<Leaks> withLeakTracking(
  Future<void> Function() callback, {
  bool throwOnLeaks = false,
  Duration? timeoutForFinalGarbageCollection,
  StackTraceCollectionConfig stackTraceCollectionConfig =
      const StackTraceCollectionConfig(),
}) async {
  enableLeakTracking(
    config: LeakTrackingConfiguration.passive(
      stackTraceCollectionConfig: stackTraceCollectionConfig,
    ),
  );

  await callback();

  await _forceGC(
    gcCycles: gcCountBuffer,
    timeout: timeoutForFinalGarbageCollection,
  );

  final result = collectLeaks();

  try {
    if (result.total > 0 && throwOnLeaks) {
      throw MemoryLeaksDetectedError(result);
    }
  } finally {
    disableLeakTracking();
  }

  return result;
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

/// Checks if the leak collection is empty.
const Matcher isLeakFree = _IsLeakFree();

class _IsLeakFree extends Matcher {
  const _IsLeakFree();

  @override
  bool matches(Object? item, Map matchState) {
    if (item is Leaks && item.total == 0) return true;
    return false;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! Leaks) {
      return mismatchDescription
        ..add(
          'The matcher applies to $Leaks and cannot be applied to ${item.runtimeType}',
        );
    }

    return mismatchDescription..add('contains leaks:\n${item.toYaml()}');
  }

  @override
  Description describe(Description description) => description.add('leak free');
}
