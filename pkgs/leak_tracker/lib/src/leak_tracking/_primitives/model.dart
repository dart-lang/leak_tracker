// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../shared/shared_model.dart';

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
    this.collectRetainingPathForNotGCed = false,
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
  final bool collectRetainingPathForNotGCed;

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

/// Leak tracking configuration.
///
/// Contains settings that cannot be changed after leak tracking is started.
class LeakTrackingConfig {
  const LeakTrackingConfig({
    this.stdoutLeaks = true,
    this.notifyDevTools = true,
    this.onLeaks,
    this.checkPeriod = const Duration(seconds: 1),
    this.disposalTime = const Duration(milliseconds: 100),
    this.numberOfGcCycles = defaultNumberOfGcCycles,
    this.maxRequestsForRetainingPath = 10,
    this.disableNotGCed = false,
    this.disableNotDisposed = false,
  });

  /// The leak tracker:
  /// - will not auto check leaks
  /// - when leak checking is invoked, will not send notifications
  /// - will set [disposalTime] to zero, to assume the methods `dispose` are completed
  /// at the moment of leak checking
  LeakTrackingConfig.passive({
    int numberOfGcCycles = defaultNumberOfGcCycles,
    int? maxRequestsForRetainingPath = 10,
  }) : this(
          stdoutLeaks: false,
          notifyDevTools: false,
          checkPeriod: null,
          disposalTime: const Duration(),
          numberOfGcCycles: numberOfGcCycles,
          maxRequestsForRetainingPath: maxRequestsForRetainingPath,
        );

  /// Number of full GC cycles, enough for a non reachable object to be GCed.
  final int numberOfGcCycles;

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

  /// Limit for number of requests for retaining path per one round
  /// of validation for leaks.
  ///
  /// If the number is too big, the performance may be seriously impacted.
  /// If null, the path will be srequested without limit.
  final int? maxRequestsForRetainingPath;

  final bool disableNotGCed;

  final bool disableNotDisposed;
}

/// Leak tracking settings for a specific phase of the application execution.
///
/// Can be used to customize leak tracking for individual tests.
class PhaseSettings {
  const PhaseSettings({
    this.notGCedAllowList = const {},
    this.notDisposedAllowList = const {},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
    this.isPaused = false,
    this.name,
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
  });

  const PhaseSettings.paused() : this(isPaused: true);

  /// When true, added objects will not be tracked.
  ///
  /// If object is added when the value is true, it will be tracked
  /// even if the value will become false during the object lifetime.
  final bool isPaused;

  /// Phase of the application execution.
  ///
  /// If not null, it will be mentioned in leak report.
  ///
  /// Can be used to specify name of a test.
  final String? name;

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

  /// What diagnostic information to collect for leaks.
  final LeakDiagnosticConfig leakDiagnosticConfig;
}
