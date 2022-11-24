// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

// ignore: unused_element
Object? _storage;

void forceGC() async {
  final gcCount = reachabilityBarrier;

  while (reachabilityBarrier <= gcCount + 1) {
    await Future.delayed(const Duration(milliseconds: 1));
    _storage = Iterable.generate(10000, (_) => DateTime.now());
    await Future.delayed(const Duration(milliseconds: 1));
    _storage = null;
  }
}
