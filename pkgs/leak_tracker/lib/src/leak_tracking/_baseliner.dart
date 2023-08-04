// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:io';

import '_primitives/_print_bytes.dart';
import '_primitives/model.dart';

class Baseliner {
  Baseliner(this.baselining)
      : rss = ValueSampler.start(initialValue: _currentRss());

  final MemoryBaselining baselining;
  final ValueSampler rss;

  static Baseliner? finishOldAndStartNew(
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
      case BaseliningMode.measure:
        if (baselining.baseline != null) {
          print(asComparison());
          print('\n\n');
        }
        print(asDartCode());
      case BaseliningMode.regression:
        throw UnimplementedError();
    }
  }

  static int _currentRss() => ProcessInfo.currentRss;

  String asDartCode() {
    return '''To set baseline, copy this code as parameter of $MemoryBaselining:
      baseline: $MemoryBaseline(
        rss: ${rss.asDartCode()},
      )''';
  }

  String asComparison() {
    final baseline = baselining.baseline;
    if (baseline == null) throw StateError('Baseline is not set.');
    final golden = baseline.rss;
    final current = rss;
    final buffer = StringBuffer();
    buffer.writeln(
      _delta('initialValue', current.initialValue, golden.initialValue),
    );
    buffer.writeln(
      _delta('deltaAvg', current.deltaAvg, golden.deltaAvg),
    );
    buffer.writeln(
      _delta('deltaMax', current.deltaMax, golden.deltaMax),
    );
    buffer.writeln(
      _delta('absAvg', current.absAvg, golden.absAvg),
    );
    buffer.writeln(
      _delta('absMax', current.absMax, golden.absMax),
    );
    buffer.writeln(
      'samples: ${current.samples} - ${golden.samples} = ${current.samples - golden.samples}',
    );
    return buffer.toString();
  }

  String _delta(String name, num current, num golden) {
    String format(num size) => prettyPrintBytes(size, includeUnit: true) ?? '';
    final delta = current - golden;
    final deltaPercent = (delta / golden * 100).toStringAsFixed(2);
    return '$name: ${format(current)} - ${format(golden)} = ${format(delta)} ($deltaPercent%)';
  }
}
