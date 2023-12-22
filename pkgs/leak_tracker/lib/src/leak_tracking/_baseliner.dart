// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:io';

import 'primitives/_print_bytes.dart';
import 'primitives/model.dart';

class Baseliner {
  Baseliner._(this.baselining)
      : assert(baselining.mode != BaseliningMode.none),
        rss = ValueSampler.start(initialValue: _currentRss());

  final MemoryBaselining baselining;
  final ValueSampler rss;

  static Baseliner? finishOldAndStartNew(
    Baseliner? oldBaseliner,
    MemoryBaselining? baselining,
  ) {
    oldBaseliner?._finish();
    if (baselining == null || baselining.mode == BaseliningMode.none) {
      return null;
    }
    return Baseliner._(baselining);
  }

  void takeSample() {
    rss.add(_currentRss());
  }

  void _finish() {
    switch (baselining.mode) {
      case BaseliningMode.measure:
        if (baselining.baseline != null) {
          print('$_asComparison\n\n\n');
          print('\n\n');
        }
        print(asDartCode());
      case BaseliningMode.regression:
        throw UnimplementedError(
            'Regression testing for memory consumption is not implemented yet. '
            'Upvote the following issue if interested: https://github.com/dart-lang/leak_tracker/issues/120');
      case BaseliningMode.none:
    }
  }

  static int _currentRss() => ProcessInfo.currentRss;

  String asDartCode() {
    return '''To set as the new baseline, set the following parameter of $MemoryBaselining:
      baseline: $MemoryBaseline(
        rss: ${rss.asDartCode()},
      )''';
  }

  String _asComparison() {
    final baseline = baselining.baseline;
    if (baseline == null) throw StateError('Baseline is not set.');
    final golden = baseline.rss;
    final current = rss;
    final buffer = StringBuffer();

    final byteEntries = [
      ('initialValue', current.initialValue, golden.initialValue),
      ('deltaAvg', current.deltaAvg, golden.deltaAvg),
      ('deltaMax', current.deltaMax, golden.deltaMax),
      ('absAvg', current.absAvg, golden.absAvg),
      ('absMax', current.absMax, golden.absMax),
    ];

    for (final e in byteEntries) {
      final (label, current, golden) = e;
      buffer.writeln(_asDelta(label, current, golden));
    }

    buffer.writeln(
      'samples: ${current.samples} - ${golden.samples} = '
      '${current.samples - golden.samples}',
    );
    return buffer.toString();
  }

  String _asDelta(String name, num current, num golden) {
    String format(num size) => prettyPrintBytes(size, includeUnit: true) ?? '';
    final delta = current - golden;
    final deltaPercent = (delta / golden * 100).toStringAsFixed(2);
    return '$name: ${format(current)} - ${format(golden)} = '
        '${format(delta)} ($deltaPercent%)';
  }
}
