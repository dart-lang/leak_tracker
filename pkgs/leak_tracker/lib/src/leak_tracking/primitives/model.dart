// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../shared/shared_model.dart';

/// Handler to collect leak summary.
typedef LeakSummaryCallback = void Function(LeakSummary);

/// Handler to collect leak information.
///
/// This is used by `LeakTrackingTestConfig.onLeaks` in
/// `package:leak_tracker_flutter_testing`.
///
/// The parameter [leaks] contains details about found leaks.
typedef LeaksCallback = void Function(Leaks leaks);

/// Set of classes to ignore during leak tracking.
@immutable
class IgnoredLeaksSet {
  /// Creates instance of [IgnoredLeaksSet].
  ///
  /// Use this constructor to provide both [byClass] and [ignoreAll]
  /// in case when you want to preserve list of classes,
  /// while temporarily turning off the entire leak tracking,
  /// so that when you turn it back on for a subset of tests
  /// with `copyWith(ignoreAll: false)`,
  /// the list of classes is set to needed value.
  const IgnoredLeaksSet({this.byClass = const {}, this.ignoreAll = false});

  const IgnoredLeaksSet.ignore() : this(ignoreAll: true, byClass: const {});

  const IgnoredLeaksSet.byClass(Map<String, int?> byClass)
      : this(byClass: byClass);

  /// Classes to ignore during leak tracking.
  ///
  /// Maps name of the class, as returned by `object.runtimeType.toString()`,
  /// to the number of instances of the class that are allowed to leak.
  ///
  /// If number of instances is `null`, all leaks are ignored.
  final Map<String, int?> byClass;

  /// If true, all leaks are ignored, otherwise
  /// [byClass] defines what is ignored.
  final bool ignoreAll;

  /// Creates a copy of this object with the given fields replaced
  /// with the new values.
  IgnoredLeaksSet copyWith({Map<String, int?>? byClass, bool? ignoreAll}) {
    return IgnoredLeaksSet(
      ignoreAll: ignoreAll ?? this.ignoreAll,
      byClass: byClass ?? this.byClass,
    );
  }

  /// Merges two ignore lists.
  ///
  /// In the result object the ignore limit for a class is
  /// the maximum of two original ignore limits.
  IgnoredLeaksSet merge(IgnoredLeaksSet? other) {
    if (other == null) return this;
    final map = {...byClass};
    for (final theClass in other.byClass.keys) {
      if (!map.containsKey(theClass)) {
        map[theClass] = other.byClass[theClass];
        continue;
      }
      final otherCount = other.byClass[theClass];
      final thisCount = byClass[theClass];
      if (thisCount == null || otherCount == null) {
        map[theClass] = null;
        continue;
      }
      map[theClass] = max(thisCount, otherCount);
    }
    return IgnoredLeaksSet(
      byClass: map,
      ignoreAll: ignoreAll || other.ignoreAll,
    );
  }

  /// Removes the classes from ignore lists.
  IgnoredLeaksSet track(List<String> list) {
    if (list.isEmpty) return this;
    final map = {...byClass};
    list.forEach(map.remove);
    return copyWith(byClass: map);
  }

  /// Returns true if the class should be ignored.
  ///
  /// Returns false if limited number of leaks is set to be ignored, that is
  /// `byClass[className] != null`.
  bool isIgnored(String className) {
    if (ignoreAll) return true;
    return byClass.containsKey(className) && byClass[className] == null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IgnoredLeaksSet &&
        other.ignoreAll == ignoreAll &&
        const DeepCollectionEquality.unordered().equals(other.byClass, byClass);
  }

  @override
  int get hashCode => Object.hash(
        ignoreAll,
        _mapHash(byClass),
      );
}

/// The total set of ignored leaks.
///
/// Includes both [experimentalNotGCed] and [notDisposed] leaks.
@immutable
class IgnoredLeaks {
  const IgnoredLeaks({
    this.experimentalNotGCed = const IgnoredLeaksSet.ignore(),
    this.notDisposed = const IgnoredLeaksSet(),
    this.createdByTestHelpers = false,
    this.testHelperExceptions = const [],
  });

  /// Ignore list for notGCed leaks.
  ///
  /// This list is experimental and may be removed in the future.
  final IgnoredLeaksSet experimentalNotGCed;

  /// Ignore list for notDisposed leaks.
  final IgnoredLeaksSet notDisposed;

  /// If true, leaking objects created by test helpers will be ignored.
  ///
  /// An object counts as created by a test helper if the stack trace of
  /// start of leak tracking contains a frame, located after the test body
  /// frame, that points to the folder `test` or the package `flutter_test`,
  /// except:
  /// * methods intended to be called from test body like `runAsync` or `pump`
  /// * frames that match [testHelperExceptions]
  final bool createdByTestHelpers;

  /// Stack frames that match this pattern will not be treated as test helpers.
  ///
  /// Is used to test functionality of
  /// the leak_tracker.
  final List<RegExp> testHelperExceptions;

  /// Returns true if the class is ignored.
  ///
  /// If [leakType] is null, returns true if the class is ignored for all
  /// leak types.
  bool isIgnored(String className, {LeakType? leakType}) {
    switch (leakType) {
      case null:
        return experimentalNotGCed.isIgnored(className) &&
            notDisposed.isIgnored(className);
      case LeakType.notDisposed:
        return notDisposed.isIgnored(className);
      case LeakType.notGCed:
      case LeakType.gcedLate:
        return experimentalNotGCed.isIgnored(className);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IgnoredLeaks &&
        other.experimentalNotGCed == experimentalNotGCed &&
        other.notDisposed == notDisposed &&
        other.createdByTestHelpers == createdByTestHelpers &&
        const DeepCollectionEquality().equals(
          other.testHelperExceptions,
          testHelperExceptions,
        );
  }

  @override
  int get hashCode => Object.hash(
        experimentalNotGCed,
        notDisposed,
        createdByTestHelpers,
        testHelperExceptions,
      );
}

/// Configuration for diagnostics.
///
/// Stacktrace and retaining path collection can
/// seriously affect performance and memory footprint.
/// So, it is recommended to have them disabled for leak detection and
/// to enable them only for leak troubleshooting.
@immutable
class LeakDiagnosticConfig {
  const LeakDiagnosticConfig({
    this.collectRetainingPathForNotGCed = false,
    this.collectStackTraceOnStart = false,
    this.collectStackTraceOnDisposal = false,
  });

  /// If true, stack trace will be collected on
  /// start of tracking for all classes.
  final bool collectStackTraceOnStart;

  /// If true, stack trace will be collected on
  /// disposal for all tracked classes.
  final bool collectStackTraceOnDisposal;

  /// If true, retaining path will be collected for non-GCed objects.
  ///
  /// The collection of retaining path is a blocking asynchronous call.
  /// In release mode this flag does not work.
  final bool collectRetainingPathForNotGCed;

  LeakDiagnosticConfig copyWith({
    bool? collectRetainingPathForNotGCed,
    bool? collectStackTraceOnStart,
    bool? collectStackTraceOnDisposal,
  }) {
    return LeakDiagnosticConfig(
      collectRetainingPathForNotGCed:
          collectRetainingPathForNotGCed ?? this.collectRetainingPathForNotGCed,
      collectStackTraceOnStart:
          collectStackTraceOnStart ?? this.collectStackTraceOnStart,
      collectStackTraceOnDisposal:
          collectStackTraceOnDisposal ?? this.collectStackTraceOnDisposal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is LeakDiagnosticConfig &&
        other.collectStackTraceOnStart == collectStackTraceOnStart &&
        other.collectStackTraceOnDisposal == collectStackTraceOnDisposal &&
        other.collectRetainingPathForNotGCed == collectRetainingPathForNotGCed;
  }

  @override
  int get hashCode => Object.hash(
        collectStackTraceOnStart,
        collectStackTraceOnDisposal,
        collectRetainingPathForNotGCed,
      );
}

/// The default value for number of full GC cycles,
/// enough for a non reachable object to be GCed.
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
    this.onLeaks,
    this.checkPeriod = const Duration(seconds: 1),
    this.disposalTime = const Duration(milliseconds: 100),
    this.numberOfGcCycles = defaultNumberOfGcCycles,
    this.maxRequestsForRetainingPath = 10,
  });

  /// The leak_tracker:
  /// - will not auto check leaks
  /// - when leak checking is invoked, will not send notifications
  /// - will set [disposalTime] to zero, to assume
  ///   the methods `dispose` are completed
  /// at the moment of leak checking
  LeakTrackingConfig.passive({
    int numberOfGcCycles = defaultNumberOfGcCycles,
    Duration disposalTime = const Duration(),
    int? maxRequestsForRetainingPath = 10,
  }) : this(
          stdoutLeaks: false,
          checkPeriod: null,
          disposalTime: disposalTime,
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

  /// Listener for leaks.
  final LeakSummaryCallback? onLeaks;

  /// Time to allow the disposal invoker to release the reference to the object.
  final Duration disposalTime;

  /// Limit for number of requests for retaining path per one round
  /// of validation for leaks.
  ///
  /// If the number is too big, the performance may be seriously impacted.
  /// If null, the path will be requested without limit.
  final int? maxRequestsForRetainingPath;
}

/// Leak tracking settings for a specific phase of the application execution.
///
/// Can be used to customize leak tracking for individual tests.
@immutable
class PhaseSettings {
  const PhaseSettings({
    this.ignoredLeaks = const IgnoredLeaks(),
    this.ignoreLeaks = false,
    this.name,
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.baselining,
  });

  const PhaseSettings.experimentalNotGCedOn()
      : this(
          ignoredLeaks:
              const IgnoredLeaks(experimentalNotGCed: IgnoredLeaksSet()),
        );

  const PhaseSettings.ignored() : this(ignoreLeaks: true);

  /// When true, added objects will not be tracked.
  ///
  /// If object is added when the value is true, it will be tracked
  /// even if the value will become false during the object lifetime.
  final bool ignoreLeaks;

  /// Phase of the application execution.
  ///
  /// If not null, it will be mentioned in leak report.
  ///
  /// Can be used to specify name of a test.
  final String? name;

  final IgnoredLeaks ignoredLeaks;

  /// What diagnostic information to collect for leaks.
  final LeakDiagnosticConfig leakDiagnosticConfig;

  final MemoryBaselining? baselining;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PhaseSettings &&
        other.ignoreLeaks == ignoreLeaks &&
        other.name == name &&
        other.ignoredLeaks == ignoredLeaks &&
        other.leakDiagnosticConfig == leakDiagnosticConfig &&
        other.baselining == baselining;
  }

  @override
  int get hashCode => Object.hash(
        ignoreLeaks,
        name,
        ignoredLeaks,
        baselining,
      );
}

int _mapHash(Map<String, int?> map) =>
    Object.hash(Object.hashAll(map.keys), Object.hashAll(map.values));

/// Settings for measuring memory footprint.
@immutable
class MemoryBaselining {
  const MemoryBaselining({
    this.mode = BaseliningMode.measure,
    this.baseline,
  }) : assert(!(mode == BaseliningMode.regression && baseline == null));

  const MemoryBaselining.none()
      : mode = BaseliningMode.none,
        baseline = null;

  final BaseliningMode mode;

  final MemoryBaseline? baseline;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MemoryBaselining &&
        other.mode == mode &&
        other.baseline == baseline;
  }

  @override
  int get hashCode => Object.hash(mode, baseline);
}

enum BaseliningMode {
  /// No baselining.
  none,

  /// Measure memory footprint and output to console when phase is finished.
  measure,

  /// Measure memory footprint, and fail if it is worse than baseline.
  regression,
}

const defaultAllowedRssDeviation = 1.3;

@immutable
class MemoryBaseline {
  const MemoryBaseline({
    // TODO(polina-c): add SDK version after fixing https://github.com/flutter/flutter/issues/61814
    this.allowedRssIncrease = defaultAllowedRssDeviation,
    required this.rss,
  });

  final ValueSampler rss;
  final double allowedRssIncrease;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MemoryBaseline &&
        other.allowedRssIncrease == allowedRssIncrease &&
        other.rss == rss;
  }

  @override
  int get hashCode => Object.hash(allowedRssIncrease, rss);
}

class ValueSampler {
  ValueSampler({
    required this.initialValue,
    required this.samples,
    required double deltaAvg,
    required this.deltaMax,
    required double absAvg,
    required this.absMax,
  })  : _sealed = true,
        _absSum = absAvg * samples,
        _deltaSum = deltaAvg * samples;

  ValueSampler.start({
    required this.initialValue,
  })  : samples = 1,
        _deltaSum = 0,
        deltaMax = 0,
        _absSum = initialValue.toDouble(),
        absMax = initialValue;

  final int initialValue;

  double _deltaSum;
  double _absSum;

  int deltaMax;
  int absMax;

  double get deltaAvg => _deltaSum / samples;
  double get absAvg => _absSum / samples;

  int samples;
  bool _sealed = false;

  /// Adds a sample.
  void add(int value) {
    if (_sealed) {
      throw StateError('Cannot add value to sealed sampler.');
    }
    absMax = max(absMax, value);
    final delta = value - initialValue;
    deltaMax = max(deltaMax, delta);

    _deltaSum += delta;
    _absSum += value;

    samples++;
  }

  void seal() {
    _sealed = true;
  }

  /// Returns dart code that constructs th object.
  String asDartCode() {
    return 'ValueSampler('
        'initialValue: $initialValue, '
        'deltaAvg: $deltaAvg, '
        'deltaMax: $deltaMax, '
        'absAvg: $absAvg, '
        'absMax: $absMax, '
        'samples: $samples,)';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ValueSampler &&
        other.initialValue == initialValue &&
        other.deltaAvg == deltaAvg &&
        other.deltaMax == deltaMax &&
        other.absAvg == absAvg &&
        other.absMax == absMax &&
        other.samples == samples &&
        other._sealed == _sealed;
  }

  @override
  int get hashCode => Object.hash(
        initialValue,
        deltaAvg,
        deltaMax,
        absAvg,
        absMax,
        samples,
        _sealed,
      );
}
