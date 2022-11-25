// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import '_model.dart';
import 'leak_analysis_events.dart';
import 'leak_analysis_model.dart';
import 'leak_tracker_model.dart';

class LeakChecker {
  LeakChecker({
    required this.leakProvider,
    required this.checkPeriod,
    required this.leakListener,
    required this.stdoutSink,
    required this.devToolsSink,
  }) {
    final period = checkPeriod;
    _timer =
        period == null ? null : Timer.periodic(period, (_) => checkLeaks());
  }

  late final Timer? _timer;

  LeakSummary _previousResult = const LeakSummary({});

  /// Period to check for leaks.
  ///
  /// If null, there is no periodic checking.
  final Duration? checkPeriod;

  // If not null, then the leak summary will be printed here, when
  // leak totals change.
  final StdoutSummarySink? stdoutSink;

  // If not null, the leak summary will be sent here, when
  // leak totals change.
  final DevToolsSummarySink? devToolsSink;

  /// Listener for leaks.
  ///
  /// Will be invoked if leak totals change.
  final LeakListener? leakListener;

  final LeakProvider leakProvider;

  void checkLeaks() {
    final summary = leakProvider.leaksSummary();
    if (summary.matches(_previousResult)) return;

    leakListener?.call(summary);
    stdoutSink?.print(summary.toMessage());
    devToolsSink?.send(summary.toJson());

    _previousResult = summary;
  }

  void dispose() {
    _timer?.cancel();
  }
}

class StdoutSummarySink {
  void print(String content) => print(content);
}

class DevToolsSummarySink {
  void send(Map<String, dynamic> content) => postEvent(
        OutgoingEventKinds.memoryLeakSummary,
        content,
      );
}
