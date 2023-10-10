// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:leak_tracker/leak_tracker.dart';

class LeakAllowList {
  const LeakAllowList._({this.byClass = const {}, this.allowAll = false});

  const LeakAllowList.allowAll() : this._(allowAll: true, byClass: const {});

  const LeakAllowList.byClass(this.byClass) : allowAll = false;

  const LeakAllowList.empty() : this._(allowAll: false, byClass: const {});

  final Map<String, int?> byClass;

  /// If true, all leaks are allowed, otherwise [byClass] defines what is allowed.
  final bool allowAll;

  LeakAllowList copyWith({Map<String, int?>? byClass, bool? allowAll}) {
    return LeakAllowList._(
      allowAll: allowAll ?? this.allowAll,
      byClass: byClass ?? this.byClass,
    );
  }

  /// Merges two allow lists.
  ///
  /// Sets maximum of allowed number of leaks.
  LeakAllowList merge(LeakAllowList? other) {
    if (other == null) return this;
    final map = {...byClass};
    for (final theClass in other.byClass.keys) {
      if (!byClass.containsKey(theClass)) {
        continue;
      }
      final int? otherCount = other.byClass[theClass];
      final int? thisCount = byClass[theClass];
      if (thisCount == null || otherCount == null) {
        map[theClass] = null;
        continue;
      }
      map[theClass] = max(thisCount, otherCount);
    }
    return LeakAllowList._(
      byClass: map,
      allowAll: allowAll || other.allowAll,
    );
  }

  /// Disallows list of classes.
  LeakAllowList disallow(List<String> list) {
    if (list.isEmpty) return this;
    final map = {...byClass};
    list.forEach(map.remove);
    return copyWith(byClass: map);
  }
}

class LeakAllowLists {
  const LeakAllowLists({
    this.notGCed = const LeakAllowList.empty(),
    this.notDisposed = const LeakAllowList.empty(),
    this.allawAll = false,
  });

  final LeakAllowList notGCed;
  final LeakAllowList notDisposed;
  final bool allawAll;
}

void _emptyLeakHandler(Leaks leaks) {}

/// Leak tracking settings for tests.
class LeakTrackingInTests {
  LeakTrackingInTests._({
    this.leakAllowLists = const LeakAllowLists(),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.failOnLeaks = true,
    this.onLeaks = _emptyLeakHandler,
    this.baselining = const MemoryBaselining.none(),
  });

  LeakTrackingInTests copyWith({
    LeakAllowLists? leakAllowLists,
    LeakDiagnosticConfig? leakDiagnosticConfig,
    bool? failOnLeaks,
    LeaksCallback? onLeaks,
    MemoryBaselining? baselining,
  }) {
    return LeakTrackingInTests._(
      leakAllowLists: leakAllowLists ?? this.leakAllowLists,
      leakDiagnosticConfig: leakDiagnosticConfig ?? this.leakDiagnosticConfig,
      failOnLeaks: failOnLeaks ?? this.failOnLeaks,
      onLeaks: onLeaks ?? this.onLeaks,
      baselining: baselining ?? this.baselining,
    );
  }

  static LeakTrackingInTests instance = LeakTrackingInTests._();

  static LeakTrackingInTests debugNotGCed() {
    return instance.copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig.debugNotGCed(),
    );
  }

  static LeakTrackingInTests debugNotDisposed() {
    return instance.copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig.debugNotDisposed(),
    );
  }

  /// Returns [instance] with extended allow lists.
  ///
  /// Sets maximum of allowed number of leaks per class.
  static LeakTrackingInTests allow({
    LeakAllowList? notGCed,
    bool? allNotGced,
    LeakAllowList? notDisposed,
    bool? allNotDisposed,
    all = false,
  }) {
    return instance.copyWith(
      leakAllowLists: LeakAllowLists(
        allawAll: instance.leakAllowLists.allawAll || all,
        notGCed: instance.leakAllowLists.notGCed.merge(notGCed),
        notDisposed: instance.leakAllowLists.notGCed.merge(notDisposed),
      ),
    );
  }

  /// Removes classes from leak allow lists.
  static LeakTrackingInTests disallow({
    notGCed = const [],
    notDisposed = const [],
  }) {
    return instance.copyWith(
      leakAllowLists: LeakAllowLists(
        allawAll: instance.leakAllowLists.allawAll,
        notGCed: instance.leakAllowLists.notGCed.disallow(notGCed),
        notDisposed: instance.leakAllowLists.notGCed.disallow(notDisposed),
      ),
    );
  }

  final bool failOnLeaks;

  final LeaksCallback onLeaks;

  final LeakAllowLists leakAllowLists;

  /// Defines which disgnostics information to collect.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;

  /// Configuration for memory baselining.
  ///
  /// Tests with deeply equal values of [MemoryBaselining],
  /// if ran sequentially, will be baselined together.
  final MemoryBaselining baselining;
}

/// Configuration, that can be set before testing start.
///
/// It will be passed to [LeakTracking.start()],
/// when invoked for first test with leak tracking.
// TODO(polina-c): remove this class in favor of [LeakTrackingInTests]
// https://github.com/flutter/devtools/issues/3951
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
// TODO(polina-c): remove this class in favor of [LeakTrackingSettings]
// https://github.com/flutter/devtools/issues/3951
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
