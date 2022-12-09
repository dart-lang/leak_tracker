// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

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
/// If invoked in tests inside `testWidget`, use `tester.runAsync`.
Future<Leaks> withLeakTracking(
  Future<void> Function() callback, {
  bool throwOnLeaks = true,
}) async {
  enableLeakTracking(
    config: LeakTrackingConfiguration.passive(),
  );

  await callback();

  await _forceGC(gcCycles: gcCountBuffer);
  final result = collectLeaks();
  if (result.total > 0 && throwOnLeaks) {
    throw MemoryLeaksDetectedError(result);
  }
  disableLeakTracking();
  return result;
}

/// Forces garbage collection by aggressive memory allocation.
Future<void> _forceGC({required int gcCycles}) async {
  final _storage = <List<DateTime>>[];

  void allocateMemory() {
    _storage.add(Iterable.generate(10000, (_) => DateTime.now()).toList());
    if (_storage.length > 100) _storage.removeAt(0);
  }

  final barrier = reachabilityBarrier;

  while (reachabilityBarrier < barrier + gcCycles) {
    await Future.delayed(const Duration());
    allocateMemory();
  }
}
