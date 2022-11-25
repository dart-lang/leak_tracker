// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'leak_analysis_model.dart';

typedef LeakListener = void Function(LeakSummary);

class LeakTrackingConfiguration {
  LeakTrackingConfiguration({
    this.stdoutLeaks = true,
    this.notifyDevTools = true,
    this.leakListener,
    this.checkPeriod = const Duration(seconds: 1),
    this.classesToCollectStackTraceOnStart = const {},
    this.classesToCollectStackTraceOnDisposal = const {},
  });

  /// The leak tracker will not auto check leaks, and, when
  /// leak checking is invoked, will notify only [listener].
  LeakTrackingConfiguration.minimal(LeakListener leakListener)
      : this(
          leakListener: leakListener,
          stdoutLeaks: false,
          notifyDevTools: false,
          checkPeriod: null,
        );

  /// Period to check for leaks.
  ///
  /// If null, there is no periodic checking.
  final Duration? checkPeriod;

  /// We use String, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnStart;

  /// We use String, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnDisposal;

  /// If true, leak information will output to console.
  final bool stdoutLeaks;

  /// If true, DevTools will be notified about leaks.
  final bool notifyDevTools;

  /// Listener for leaks.
  final LeakListener? leakListener;
}
