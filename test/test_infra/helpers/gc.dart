// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

/// Forces garbage collection by aggressive memory allocation.
Future<void> forceGC({required int gcCycles}) async {
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
