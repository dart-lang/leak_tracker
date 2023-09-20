// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:collection/collection.dart';

import '../../shared/shared_model.dart';

/// Handler to collect leak summary.
typedef LeakSummaryCallback = void Function(LeakSummary);

/// Handler to collect leak information.
///
/// Used by [LeakTrackingTestConfig.onLeaks].
/// The parameter [leaks] contains details about found leaks.
typedef LeaksCallback = void Function(Leaks leaks);

/// Switches for features of leak tracker.
///
/// Useable to temporary disable features in case of
/// noisinness or performance regression
/// in applications or tests.
class Switches {
  const Switches({
    this.disableNotGCed = false,
    this.disableNotDisposed = false,
  });

  /// If true, notGCed leaks will not be tracked.
  final bool disableNotGCed;

  /// If true, notDisposed leaks will not be tracked.
  final bool disableNotDisposed;

  /// If true, objects are not tracked.
  bool get isObjectTrackingDisabled => disableNotDisposed && disableNotGCed;
}

/// Configuration for diagnostics.
///
/// Stacktrace and retaining path collection can seriously affect performance and memory footprint.
/// So, it is recommended to have them disabled for leak detection and to enable them
/// only for leak troubleshooting.
class LeakDiagnosticConfig {
  const LeakDiagnosticConfig({
    this.collectRetainingPathForNotGCed = false,
    this.collectStackTraceOnStart = false,
    this.collectStackTraceOnDisposal = false,
  });

  /// If true, stack trace will be collected on start of tracking for all classes.
  final bool collectStackTraceOnStart;

  /// If true, stack trace will be collected on disposal for all tracked classes.
  final bool collectStackTraceOnDisposal;

  /// If true, retaining path will be collected for non-GCed objects.
  ///
  /// The collection of retaining path a blocking asyncronous call.
  /// In release mode this flag does not work.
  final bool collectRetainingPathForNotGCed;

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
    this.switches = const Switches(),
  });

  /// The leak tracker:
  /// - will not auto check leaks
  /// - when leak checking is invoked, will not send notifications
  /// - will set [disposalTime] to zero, to assume the methods `dispose` are completed
  /// at the moment of leak checking
  LeakTrackingConfig.passive({
    int numberOfGcCycles = defaultNumberOfGcCycles,
    Duration disposalTime = const Duration(),
    int? maxRequestsForRetainingPath = 10,
    Switches switches = const Switches(),
  }) : this(
          stdoutLeaks: false,
          notifyDevTools: false,
          checkPeriod: null,
          disposalTime: disposalTime,
          numberOfGcCycles: numberOfGcCycles,
          maxRequestsForRetainingPath: maxRequestsForRetainingPath,
          switches: switches,
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

  /// Switches for features of leak tracker.
  final Switches switches;
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
    this.isLeakTrackingPaused = false,
    this.name,
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.baselining,
  });

  const PhaseSettings.paused() : this(isLeakTrackingPaused: true);

  /// When true, added objects will not be tracked.
  ///
  /// If object is added when the value is true, it will be tracked
  /// even if the value will become false during the object lifetime.
  final bool isLeakTrackingPaused;

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
        other.isLeakTrackingPaused == isLeakTrackingPaused &&
        other.name == name &&
        const DeepCollectionEquality.unordered()
            .equals(other.notDisposedAllowList, notDisposedAllowList) &&
        const DeepCollectionEquality.unordered()
            .equals(other.notGCedAllowList, notGCedAllowList) &&
        other.allowAllNotDisposed == allowAllNotDisposed &&
        other.allowAllNotGCed == allowAllNotGCed &&
        other.leakDiagnosticConfig == leakDiagnosticConfig &&
        other.baselining == baselining;
  }

  @override
  int get hashCode => Object.hash(
        isLeakTrackingPaused,
        name,
        _mapHash(notDisposedAllowList),
        _mapHash(notGCedAllowList),
        allowAllNotDisposed,
        allowAllNotGCed,
        baselining,
      );
}

int _mapHash(Map<String, int?> map) =>
    Object.hash(Object.hashAll(map.keys), Object.hashAll(map.values));

/// Settings for measuring memory footprint.
class MemoryBaselining {
  const MemoryBaselining({
    this.mode = BaseliningMode.measure,
    this.baseline,
  }) : assert(!(mode == BaseliningMode.regression && baseline == null));

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
  /// Measure memory footprint and output to console when phase is finished.
  measure,

  /// Measure memory footprint, and fail if it is worse than baseline.
  regression,
}

const defaultAllowedRssDeviation = 1.3;

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
    required deltaAvg,
    required this.deltaMax,
    required absAvg,
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
