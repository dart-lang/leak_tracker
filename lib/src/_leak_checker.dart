// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'leak_analysis_model.dart';
import 'leak_tracker_model.dart';

class LeakChecker {
  LeakChecker({
    required this.leakProvider,
    required this.checkPeriod,
    required this.leakListener,
    required this.stdoutLeaks,
    required this.notifyDevTools,
    StdoutSink? stdoutSink,
    DevToolsSink? devToolsSink,
  })  : stdoutSink = stdoutSink ?? StdoutSink(),
        devToolsSink = devToolsSink ?? DevToolsSink() {
    final period = checkPeriod;
    _timer = period == null ? null : Timer.periodic(period, (_) => checkLeaks);
  }

  late final Timer? _timer;

  LeakSummary _previousResult = LeakSummary({});

  /// Period to check for leaks.
  ///
  /// If null, there is no periodic checking.
  final Duration? checkPeriod;

  /// If true, the tool will output the leak summary to console when
  /// leak totals change.
  final bool stdoutLeaks;

  /// If true, DevTools will notify DevTools when
  /// leak totals change.
  final bool notifyDevTools;

  StdoutSink stdoutSink;

  DevToolsSink devToolsSink;

  /// Listener for leaks.
  ///
  /// Will be invoked if leak totals change.
  final LeakListener? leakListener;

  final LeakProvider leakProvider;

  void checkLeaks() {
    final summary = leakProvider.leaksSummary();
    if (summary.matches(_previousResult)) return;

    leakListener?.call(summary);
    if (stdoutLeaks) print(summary.toMessage());
    _previousResult = summary;
  }

  void dispose() {
    _timer?.cancel();
  }
}

class StdoutSink {
  void print(String content) => print(content);
}

class DevToolsSink {
  void send(Map<String, dynamic> content) =>
      postEvent(EventNames.memoryLeaksSummary, content);
}
