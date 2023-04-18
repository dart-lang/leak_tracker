// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'shared_model.dart';

/// Handler to collect leak summary.
typedef LeakSummaryCallback = void Function(LeakSummary);

/// Handler to collect leak information.
///
/// Used by [LeakTrackingTestConfig.onLeaks].
/// The parameter [leaks] contains details about found leaks.
typedef LeaksCallback = void Function(Leaks leaks);

/// Configuration of stack trace collection.
///
/// Stacktrace collection can seriously affect performance and memory footprint.
/// So, it is recommended to have it disabled for leak detection and to enable it
/// only for leak troubleshooting.
class StackTraceCollectionConfig {
  const StackTraceCollectionConfig({
    this.classesToCollectStackTraceOnStart = const {},
    this.classesToCollectStackTraceOnDisposal = const {},
    this.collectStackTraceOnStart = false,
    this.collectStackTraceOnDisposal = false,
  });

  /// Set of classes to collect callstack on tracking start.
  ///
  /// Ignored if [collectStackTraceOnStart] is true.
  /// String is used, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnStart;

  /// Set of classes to collect callstack on disposal.
  ///
  /// Ignored if [collectStackTraceOnDisposal] is true.
  /// String is used, because some types are private and thus not accessible.
  final Set<String> classesToCollectStackTraceOnDisposal;

  /// If true, stack trace will be collected on start of tracking for all classes.
  final bool collectStackTraceOnStart;

  /// If true, stack trace will be collected on disposal for all tracked classes.
  final bool collectStackTraceOnDisposal;

  bool shouldCollectOnStart(String classname) =>
      collectStackTraceOnStart ||
      classesToCollectStackTraceOnStart.contains(classname);

  bool shouldCollectOnDisposal(String classname) =>
      collectStackTraceOnDisposal ||
      classesToCollectStackTraceOnDisposal.contains(classname);
}

class LeakTrackingConfiguration {
  const LeakTrackingConfiguration({
    this.stdoutLeaks = true,
    this.notifyDevTools = true,
    this.onLeaks,
    this.checkPeriod = const Duration(seconds: 1),
    this.disposalTimeBuffer = const Duration(milliseconds: 100),
    this.stackTraceCollectionConfig = const StackTraceCollectionConfig(),
  });

  /// The leak tracker:
  /// - will not auto check leaks
  /// - when leak checking is invoked, will not send notifications
  /// - will assume the methods `dispose` are completed
  /// at the moment of leak checking.
  LeakTrackingConfiguration.passive({
    StackTraceCollectionConfig stackTraceCollectionConfig =
        const StackTraceCollectionConfig(),
  }) : this(
          stdoutLeaks: false,
          notifyDevTools: false,
          checkPeriod: null,
          disposalTimeBuffer: const Duration(),
          stackTraceCollectionConfig: stackTraceCollectionConfig,
        );

  final StackTraceCollectionConfig stackTraceCollectionConfig;

  /// Period to check for leaks.
  ///
  /// If null, there is no periodic checking.
  final Duration? checkPeriod;

  /// If true, leak information will output to console.
  final bool stdoutLeaks;

  /// If true, DevTools will be notified about leaks.
  final bool notifyDevTools;

  /// Listener for leaks.
  final LeakSummaryCallback? onLeaks;

  /// Time to allow the disposal invoker to release the reference to the object.
  ///
  /// The default value is pessimistic assuming that user will want to
  /// detect leaks not more often than a second.
  final Duration disposalTimeBuffer;
}

/// Configuration for leak trecking in unit tests.
///
/// The configuration is needed only for test debugging,
/// not for regular test run.
class LeakTrackingTestConfig {
  /// Creates a new instance of [LeakTrackingFlutterTestConfig].
  const LeakTrackingTestConfig({
    this.stackTraceCollectionConfig = const StackTraceCollectionConfig(),
    this.onLeaks,
    this.failTestOnLeaks = true,
  });

  /// When to collect stack trace information.
  ///
  /// You may need to know call stack to troubleshoot memory leaks.
  /// Custonize this parameter to collect stack traces when needed.
  final StackTraceCollectionConfig stackTraceCollectionConfig;

  /// Handler to obtain details about collected leaks.
  ///
  /// Use the handler to process the collected leak
  /// details programmatically.
  final LeaksCallback? onLeaks;

  /// If true, the test will fail if leaks are found.
  ///
  /// Set it to false if you want the test to pass, in order
  /// to analyze the found leaks after the test execution.
  final bool failTestOnLeaks;
}
