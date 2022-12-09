// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'shared_model.dart';

typedef LeakListener = void Function(LeakSummary);

class LeakTrackingConfiguration {
  LeakTrackingConfiguration({
    this.stdoutLeaks = true,
    this.notifyDevTools = true,
    this.leakListener,
    this.checkPeriod = const Duration(seconds: 1),
    this.classesToCollectStackTraceOnStart = const {},
    this.classesToCollectStackTraceOnDisposal = const {},
    this.disposalTimeBuffer = const Duration(milliseconds: 100),
  });

  /// The leak tracker:
  /// - will not auto check leaks
  /// - when leak checking is invoked, will not send notifications
  /// - will assume the methods `dispose` are completed
  /// at the moment of leak checking.
  LeakTrackingConfiguration.passive({
    Set<String> classesToCollectStackTraceOnStart = const {},
    Set<String> classesToCollectStackTraceOnDisposal = const {},
  }) : this(
          stdoutLeaks: false,
          notifyDevTools: false,
          checkPeriod: null,
          disposalTimeBuffer: const Duration(),
          classesToCollectStackTraceOnStart: classesToCollectStackTraceOnStart,
          classesToCollectStackTraceOnDisposal:
              classesToCollectStackTraceOnDisposal,
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

  /// Time to allow the disposal invoker to release the reference to the object.
  ///
  /// The default value is pessimistic assuming that user will want to
  /// detect leaks not more often than a second.
  final Duration disposalTimeBuffer;
}
