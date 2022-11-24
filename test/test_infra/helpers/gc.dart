// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

final _storage = <List<DateTime>>[];
void _allocateMemory() {
  _storage.add(Iterable.generate(10000, (_) => DateTime.now()).toList());
}

Future<void> forceGC() async {
  final barrier = reachabilityBarrier;

  while (reachabilityBarrier <= barrier + 2) {
    await Future.delayed(const Duration());
    _allocateMemory();
  }
  _storage.clear();
}
