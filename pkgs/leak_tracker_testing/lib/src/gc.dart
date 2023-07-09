// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

/// Forces garbage collection by aggressive memory allocation.
///
/// Verifies that garbage collection happened using [reachabilityBarrier].
/// Does not work in web and in release mode.
///
/// Use [timeout] to limit waitning time.
/// Use [fullGcCycles] to force multiple garbage collections.
///
/// The methot is useable for testing in combination with [WeakReference] to ensure
/// an object is not held by another object from garbage collection.
///
/// For code example see ../../test/gc_test.dart.
/// TODO(polina-c): add link to GitHub when this code gets merged.
Future<void> forceGC({
  Duration? timeout,
  int fullGcCycles = 1,
}) async {
  final Stopwatch? stopwatch = timeout == null ? null : (Stopwatch()..start());
  final int barrier = reachabilityBarrier;

  final List<List<DateTime>> storage = <List<DateTime>>[];

  void allocateMemory() {
    storage.add(
      Iterable<DateTime>.generate(10000, (_) => DateTime.now()).toList(),
    );
    if (storage.length > 100) {
      storage.removeAt(0);
    }
  }

  while (reachabilityBarrier < barrier + fullGcCycles) {
    if ((stopwatch?.elapsed ?? Duration.zero) > (timeout ?? Duration.zero)) {
      throw TimeoutException('forceGC timed out', timeout);
    }
    await Future<void>.delayed(Duration.zero);
    allocateMemory();
  }
}
