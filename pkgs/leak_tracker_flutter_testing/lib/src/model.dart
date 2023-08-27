// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';

/// Configuration, that can be set before testing start.
///
/// It will be passed to [LeakTracking.start()],
/// when invoked for first test with leak tracking.
class LeakTrackingTestSettings {
  LeakTrackingTestSettings({
    this.switches = const Switches(),
    this.numberOfGcCycles = defaultNumberOfGcCycles,
    this.disposalTime = Duration.zero,
  });

  /// Switches for leak tracking features.
  final Switches switches;

  /// Number of full GC cycles to wait after disposal, to declare leak if the object is still not GCed.
  final int numberOfGcCycles;

  /// Time to allow the reference to the object to be released
  /// by garbage collector and for finalizer to be invoked,
  /// after disposal.
  final Duration disposalTime;
}

/// Configuration for leak tracking to pass to an individual unit test.
///
/// Customized configuration is needed only for test debugging,
/// not for regular test runs.
class LeakTrackingTestConfig {
  /// Creates a new instance of [LeakTrackingTestConfig].
  const LeakTrackingTestConfig({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
    this.baselining,
    this.isLeakTrackingPaused = false,
  });

  /// Creates a new instance for debugging leaks.
  ///
  /// This configuration will collect stack traces on start and disposal,
  /// and the objects' retaining paths for notGCed objects.
  LeakTrackingTestConfig.debug({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectStackTraceOnStart: true,
      collectStackTraceOnDisposal: true,
      collectRetainingPathForNotGCed: true,
    ),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
    this.baselining,
    this.isLeakTrackingPaused = false,
  });

  /// Creates a new instance for debugging notGCed leaks.
  ///
  /// This configuration will collect stack traces on disposal,
  /// and the objects' retaining paths for notGCed objects.
  LeakTrackingTestConfig.debugNotGCed({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectStackTraceOnDisposal: true,
      collectRetainingPathForNotGCed: true,
    ),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
    this.baselining,
    this.isLeakTrackingPaused = false,
  });

  /// Creates a new instance for debugging notDisposed leaks.
  ///
  /// This configuration will collect stack traces on start and disposal,
  /// and retaining path for notGCed objects.
  LeakTrackingTestConfig.debugNotDisposed({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectStackTraceOnStart: true,
    ),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
    this.baselining,
    this.isLeakTrackingPaused = false,
  });

  /// Creates a new instance to collect retaining path.
  ///
  /// This configuration will not collect stack traces,
  /// and will collect retaining path for notGCed objects.
  const LeakTrackingTestConfig.retainingPath({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectRetainingPathForNotGCed: true,
    ),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
    this.baselining,
    this.isLeakTrackingPaused = false,
  });

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

  /// When to collect stack trace information.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;

  /// Configuration for memory baselining.
  ///
  /// Tests with deeply equal values of [MemoryBaselining],
  /// if ran sequentially, will be baselined together.
  final MemoryBaselining? baselining;

  /// If true, leak tracking will not happen.
  final bool isLeakTrackingPaused;
}
