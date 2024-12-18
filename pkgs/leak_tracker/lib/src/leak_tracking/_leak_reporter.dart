// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../shared/_util.dart';
import '../shared/shared_model.dart';
import 'primitives/model.dart';

/// Checks [leakProvider] either by schedule or by request.
///
/// If there are leaks, reports them to the enabled outputs:
/// listener and console.
class LeakReporter {
  LeakReporter({
    required this.leakProvider,
    required this.checkPeriod,
    required this.onLeaks,
    required this.stdoutSink,
  }) {
    final period = checkPeriod;
    _timer = period == null
        ? null
        : Timer.periodic(period, (_) async => await checkLeaks());
  }

  late final Timer? _timer;

  LeakSummary _previousResult = LeakSummary({});

  /// Period to check for leaks.
  ///
  /// If null, there is no periodic checking.
  final Duration? checkPeriod;

  // If not null, then the leak summary will be printed here, when
  // leak totals change.
  final StdoutSummarySink? stdoutSink;

  /// Listener for leaks.
  ///
  /// Will be invoked if leak totals change.
  final LeakSummaryCallback? onLeaks;

  final LeakProvider leakProvider;

  /// Checks leaks, if there are new ones, send notifications.
  Future<LeakSummary> checkLeaks() async {
    final summary = await leakProvider.leaksSummary();

    if (!summary.matches(_previousResult)) {
      onLeaks?.call(summary);
      stdoutSink?.send(summary);

      _previousResult = summary;
    }
    return summary;
  }

  void dispose() {
    _timer?.cancel();
  }
}

class StdoutSummarySink {
  void send(LeakSummary summary) => printToConsole(summary.toMessage());
}
