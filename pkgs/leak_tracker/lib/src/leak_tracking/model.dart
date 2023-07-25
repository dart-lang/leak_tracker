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
  const LeakDiagnosticConfig({
    this.collectRetainingPathForNonGCed = false,
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

  /// If true, retaining path will be collected for non-GCed objects.
  ///
  /// The collection of retaining path a blocking asyncronous call.
  /// In release mode this flag does not work.
  final bool collectRetainingPathForNonGCed;

  bool shouldCollectStackTraceOnStart(String classname) =>
      collectStackTraceOnStart ||
      classesToCollectStackTraceOnStart.contains(classname);

  bool shouldCollectStackTraceOnDisposal(String classname) =>
      collectStackTraceOnDisposal ||
      classesToCollectStackTraceOnDisposal.contains(classname);
}

/// The default value for number of full GC cycles, enough for a non reachable object to be GCed.
///
/// It is pessimistic assuming that user will want to
/// detect leaks not more often than a second.
///
/// Theoretically, 2 should be enough, however it gives false positives
/// if there is no activity in the application for ~5 minutes.
const defaultNumberOfGcCycles = 3;

/// Leak tracking configuration, that cannot be changed after leak tracking is started.
class LeakTrackingConfiguration {
  const LeakTrackingConfiguration({
    this.stdoutLeaks = true,
    this.notifyDevTools = true,
    this.onLeaks,
    this.checkPeriod = const Duration(seconds: 1),
    this.disposalTime = const Duration(milliseconds: 100),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.numberOfGcCycles = defaultNumberOfGcCycles,
    this.warnForNonSupportedPlatforms = true,
    this.maxRequestsForRetainingPath = 10,
  });

  /// The leak tracker:
  /// - will not auto check leaks
  /// - when leak checking is invoked, will not send notifications
  /// - will assume the methods `dispose` are completed
  /// at the moment of leak checking.
  LeakTrackingConfiguration.passive({
    LeakDiagnosticConfig leakDiagnosticConfig = const LeakDiagnosticConfig(),
    int numberOfGcCycles = defaultNumberOfGcCycles,
  }) : this(
          stdoutLeaks: false,
          notifyDevTools: false,
          checkPeriod: null,
          disposalTime: const Duration(),
          leakDiagnosticConfig: leakDiagnosticConfig,
          numberOfGcCycles: numberOfGcCycles,
        );

  /// Number of full GC cycles, enough for a non reachable object to be GCed.
  final int numberOfGcCycles;

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
  final Duration disposalTime;

  /// If true, a warning will be printed when leak tracking is
  /// requested for a non-supported platform.
  final bool warnForNonSupportedPlatforms;

  /// Limit for number of requests for retaining path per one round
  /// of validation for leaks.
  ///
  /// If the number is too big, the performance may be seriously impacted.
  /// If null, the path will be srequested without limit.
  final int? maxRequestsForRetainingPath;
}

/// Configuration for leak tracking in unit tests.
///
/// Customized configuration is needed only for test debugging,
/// not for regular test runs.
// TODO(polina-c): update helpers to respect allow lists defined in this class
// https://github.com/flutter/devtools/issues/5606
class LeakTrackingTestConfig {
  /// Creates a new instance of [LeakTrackingTestConfig].
  const LeakTrackingTestConfig({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// Creates a new instance of [LeakTrackingTestConfig] for debugging leaks.
  ///
  /// This configuration will collect stack traces on start and disposal,
  /// and retaining path for notGCed objects.
  LeakTrackingTestConfig.debug({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectStackTraceOnStart: true,
      collectStackTraceOnDisposal: true,
      collectRetainingPathForNonGCed: true,
    ),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// Creates a new instance of [LeakTrackingTestConfig] to collect retaining path.
  ///
  /// This configuration will not collect stack traces,
  /// and will collect retaining path for notGCed objects.
  LeakTrackingTestConfig.retainingPath({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectRetainingPathForNonGCed: true,
    ),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// When to collect stack trace information.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;

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

  /// If true, all notDisposed leaks will be allowed.
  final bool allowAllNotDisposed;

  /// If true, all notGCed leaks will be allowed.
  final bool allowAllNotGCed;
}
