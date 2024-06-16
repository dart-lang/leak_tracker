// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import '../shared/_formatting.dart';
import 'primitives/_retaining_path/_connection.dart';
import 'primitives/_retaining_path/_retaining_path.dart';

/// Forces garbage collection by aggressive memory allocation.
///
/// Verifies that garbage collection happened using [reachabilityBarrier].
/// Does not work in web and in release mode.
///
/// Use [timeout] to limit waiting time.
/// Use [fullGcCycles] to force multiple garbage collections.
///
/// The method is helpful for testing in combination with [WeakReference] to
/// ensure an object is not held by another object from garbage collection.
///
/// For code example see
/// https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/TROUBLESHOOT.md
Future<void> forceGC({
  Duration? timeout,
  int fullGcCycles = 1,
}) async {
  final stopwatch = timeout == null ? null : (Stopwatch()..start());
  final barrier = reachabilityBarrier;

  final storage = <List<int>>[];

  void allocateMemory() {
    storage.add(List.generate(30000, (n) => n));
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

/// Returns nicely formatted retaining path for the [WeakReference.target].
///
/// If the object is garbage collected or not retained, returns null.
///
/// Does not work in web and in release mode.
///
/// To run this inside `flutter test` pass `--enable-vmservice`.
///
/// Also does not work for objects that are not returned by getInstances.
/// https://github.com/dart-lang/sdk/blob/3e80d29fd6fec56187d651ce22ea81f1e8732214/runtime/vm/object_graph.cc#L1803
Future<String?> formattedRetainingPath(WeakReference ref) async {
  if (ref.target == null) return null;
  final connection = await connect();
  final path = await retainingPath(
    connection,
    ref.target,
  );

  if (path == null) return null;
  return retainingPathToString(path);
}
