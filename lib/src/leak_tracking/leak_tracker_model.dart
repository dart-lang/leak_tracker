// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared_model.dart';

/// Handler to collect leak summary.
typedef LeakSummaryCallback = void Function(LeakSummary);

/// Handler to collect leak information.
///
/// Used by [LeakTrackingTestConfig.onLeaks].
/// The parameter [leaks] contains details about found leaks.
typedef LeaksCallback = void Function(Leaks leaks);

/// Configuration for diagnostics.
///
/// Stacktrace and retaining path collection can seriously affect performance and memory footprint.
/// So, it is recommended to have them disabled for leak detection and to enable them
/// only for leak troubleshooting.
class LeakDiagnosticConfig {
  LeakDiagnosticConfig({
    this.collectRetainingPathForNonGCed = false,
    this.classesToCollectStackTraceOnStart = const {},
    this.classesToCollectStackTraceOnDisposal = const {},
    this.collectStackTraceOnStart = false,
    this.collectStackTraceOnDisposal = false,
  }) {
    _checkMode();
  }

  const LeakDiagnosticConfig.empty()
      : collectRetainingPathForNonGCed = false,
        classesToCollectStackTraceOnStart = const {},
        classesToCollectStackTraceOnDisposal = const {},
        collectStackTraceOnStart = false,
        collectStackTraceOnDisposal = false;

  void _checkMode() {
    if (collectRetainingPathForNonGCed) {
      var isReleaseMode = true;
      assert(() {
        isReleaseMode = false;
        return true;
      }());

      if (isReleaseMode) {
        throw AssertionError(
          'collectRetainingPathForNonGCed is not supported in release mode.',
        );
      }
    }
  }

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

  /// If true, retaining path will be collected for non-GCed objects.
  ///
  /// In release mode this flag does not work.
  final bool collectRetainingPathForNonGCed;

  bool shouldCollectStackTraceOnStart(String classname) =>
      collectStackTraceOnStart ||
      classesToCollectStackTraceOnStart.contains(classname);

  bool shouldCollectStackTraceOnDisposal(String classname) =>
      collectStackTraceOnDisposal ||
      classesToCollectStackTraceOnDisposal.contains(classname);
}

class LeakTrackingConfiguration {
  LeakTrackingConfiguration({
    this.stdoutLeaks = true,
    this.notifyDevTools = true,
    this.onLeaks,
    this.checkPeriod = const Duration(seconds: 1),
    this.disposalTimeBuffer = const Duration(milliseconds: 100),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig.empty(),
  });

  /// The leak tracker:
  /// - will not auto check leaks
  /// - when leak checking is invoked, will not send notifications
  /// - will assume the methods `dispose` are completed
  /// at the moment of leak checking.
  LeakTrackingConfiguration.passive({
    LeakDiagnosticConfig leakDiagnosticConfig =
        const LeakDiagnosticConfig.empty(),
  }) : this(
          stdoutLeaks: false,
          notifyDevTools: false,
          checkPeriod: null,
          disposalTimeBuffer: const Duration(),
          leakDiagnosticConfig: leakDiagnosticConfig,
        );

  final LeakDiagnosticConfig leakDiagnosticConfig;

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

/// Configuration for leak tracking in unit tests.
///
/// Customized configuration is needed only for test debugging,
/// not for regular test runs.
class LeakTrackingTestConfig {
  /// Creates a new instance of [LeakTrackingFlutterTestConfig].
  LeakTrackingTestConfig({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig.empty(),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
  });

  /// Creates a new instance of [LeakTrackingFlutterTestConfig] for debugging leaks.
  LeakTrackingTestConfig.debug({
    LeakDiagnosticConfig? leakDiagnosticConfig,
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
  }) {
    this.leakDiagnosticConfig = leakDiagnosticConfig ??
        LeakDiagnosticConfig(
          collectStackTraceOnStart: true,
          collectStackTraceOnDisposal: true,
          collectRetainingPathForNonGCed: true,
        );
  }

  /// If true, a warning will be printed when leak tracking is
  /// requested for a non-supported platform.
  static bool warnForNonSupportedPlatforms = true;

  /// When to collect stack trace information.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  late LeakDiagnosticConfig leakDiagnosticConfig;

  /// Handler to obtain details about collected leaks.
  ///
  /// Use the handler to process the collected leak
  /// details programmatically.
  final LeaksCallback? onLeaks;

  /// If true, the test will fail if leaks are found.
  ///
  /// If false, the test will not fail if leaks are
  /// found to allow for analyzing leaks after the test completes.
  final bool failTestOnLeaks;

  /// Classes that are allowed to be not garbage collected after disposal.
  ///
  /// Maps name of the class, as returned by `object.runtimeType.toString()`,
  /// to the number of instances of the class that are allowed to be not GCed.
  ///
  /// If number of instances is [null], any number of instances is allowed.
  final Map<String, int?> notGCedAllowList;

  /// Classes that are allowed to be garbage collected without being disposed.
  ///
  /// Maps name of the class, as returned by `object.runtimeType.toString()`,
  /// to the number of instances of the class that are allowed to be not disposed.
  ///
  /// If number of instances is [null], any number of instances is allowed.
  final Map<String, int?> notDisposedAllowList;
}
