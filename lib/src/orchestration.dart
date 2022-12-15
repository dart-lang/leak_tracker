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

class MemoryLeaksDetectedError extends StateError {
  MemoryLeaksDetectedError(this.leaks) : super('Leaks detected.');

  final Leaks leaks;
}

/// Tests the functionality with leak tracking.
///
/// If invoked inside `testWidget`, use `tester.runAsync`:
/// ```
/// await tester.runAsync(() async {
///   await withLeakTracking(() async {
///     ...
///   });
/// });
/// ```
///
Future<Leaks> withLeakTracking(
  Future<void> Function() callback, {
  bool throwOnLeaks = true,
  Duration? timeoutForFinalGarbageCollection,
}) async {
  enableLeakTracking(
    config: LeakTrackingConfiguration.passive(),
  );

  await callback();

  await _forceGC(
    gcCycles: gcCountBuffer,
    timeout: timeoutForFinalGarbageCollection,
  );

  final result = collectLeaks();
  if (result.total > 0 && throwOnLeaks) {
    throw MemoryLeaksDetectedError(result);
  }
  disableLeakTracking();
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
