// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'leak_analysis_model.dart';

typedef LeakListener = void Function(LeakSummary);

class LeakTrackingConfiguration {
  LeakTrackingConfiguration({
    this.leakListener,
    this.stdoutLeaks = true,
    this.checkPeriod = const Duration(seconds: 1),
    this.classesToCollectStackTraceOnTrackingStart = const {},
    this.classesToCollectStackTraceOnDisposal = const {},
  });

  /// Period to check for leaks.
  ///
  /// If null, there is no periodic checking.
  final Duration? checkPeriod;

  /// We use String, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnTrackingStart;

  /// We use String, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnDisposal;

  /// If true, the tool will output the leak summary to console.
  final bool stdoutLeaks;

  /// Listener for leaks.
  final LeakListener? leakListener;
}
