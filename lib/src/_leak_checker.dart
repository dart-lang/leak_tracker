// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'leak_analysis_model.dart';
import 'leak_tracker_model.dart';

class LeakChecker {
  LeakChecker({
    required this.leakProvider,
    required this.leakListener,
    required this.stdoutLeaks,
    required this.checkPeriod,
  }) {
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

  /// Listener for leaks.
  ///
  /// Will be invoked if number of leaks is different since previous check.
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
