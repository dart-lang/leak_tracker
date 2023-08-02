// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_primitives/model.dart';

class Baseliner {
  static Baseliner? wrapOldAndStartNew(
    Baseliner? oldBaseliner,
    MemoryBaselining? baselining,
  ) {
    oldBaseliner?.stop();
    if (baselining == null) return null;
    return Baseliner._start(baselining);
  }

  static Baseliner _start(MemoryBaselining baselining) {
    throw UnimplementedError();
  }

  void stop() {}
}
