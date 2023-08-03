// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '_primitives/model.dart';

class Baseliner {
  Baseliner(this.baselining)
      : rss = ValueSampler.start(initialValue: _currentRss());

  final MemoryBaselining baselining;
  final ValueSampler rss;

  static Baseliner? wrapOldAndStartNew(
    Baseliner? oldBaseliner,
    MemoryBaselining? baselining,
  ) {
    oldBaseliner?._finish();
    if (baselining == null) return null;
    return Baseliner(baselining);
  }

  void takeSample() {
    rss.add(_currentRss());
  }

  void _finish() {
    switch (baselining.mode) {
      case BaseliningMode.output:
        print(asDartCode());
      case BaseliningMode.compare:
        throw UnimplementedError();
      case BaseliningMode.regression:
        throw UnimplementedError();
    }
  }

  static int _currentRss() => ProcessInfo.currentRss;

  String asDartCode() {
    return '''Copy this code as your test parameter:
      baselining: MemoryBaselining(
        mode: BaseliningMode.compare,
        baseline: MemoryBaseline(
          rss: ${rss.asDartCode()},
        ),
      )''';
  }
}
