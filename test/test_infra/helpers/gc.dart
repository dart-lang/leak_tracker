// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

/// Forces garbage collection by aggressive memory allocation.
Future<void> forceGC() async {
  final _storage = <List<DateTime>>[];

  void allocateMemory() {
    _storage.add(Iterable.generate(10000, (_) => DateTime.now()).toList());
  }

  final barrier = reachabilityBarrier;

  while (reachabilityBarrier < barrier + 2) {
    await Future.delayed(const Duration());
    allocateMemory();
  }
}
