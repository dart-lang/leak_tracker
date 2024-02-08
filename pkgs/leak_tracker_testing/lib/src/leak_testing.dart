// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:matcher/expect.dart';
import 'package:meta/meta.dart';

import 'matchers.dart';

/// leak_tracker settings for tests.
///
/// Set [LeakTesting.settings], to
/// change default leak tracking settings for tests.
/// Set it for package or folder in flutter_test_config.dart and for
/// a test file in `setUpAll`.
///
/// If you update the settings for a group, remember the original value to a
/// local variable and restore it in `tearDownAll` for the group.
///
/// Use methods that return adjusted [LeakTesting.settings]
/// to customize default for an individual test:
///
/// ```dart
/// testWidgets(
///     'initialTimerDuration falls within limit',
///     leakTracking: LeakTesting.settings.withIgnoredAll(),
///     (WidgetTester tester) async {
///       ...
/// ```
///
/// If [LeakTesting.settings] are updated during a test run,
/// the new value will be used for the next test.
@immutable
class LeakTesting {
  const LeakTesting._({
    this.ignore = false,
    this.ignoredLeaks = const IgnoredLeaks(),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.baselining = const MemoryBaselining.none(),
  });

  static bool _enabled = false;

  /// If true, leak tracking is enabled.
  ///
  /// If value is true before a test `main` started,
  /// [settings] will be respected during testing.
  /// Use this property to enable leak tracking.
  ///
  /// To turn leak tracking off/on for individual tests
  /// after enabling, use [ignore].
  static bool get enabled => _enabled;

  /// Invoke in flutter_test_config.dart to enable leak tracking.
  ///
  /// Use [withIgnoredAll] and [withTrackedAll], to pause/resume
  /// leak tracking after it is enabled.
  static void enable() => _enabled = true;

  /// Handler for memory leaks found in tests.
  ///
  /// Set it to analyze the leaks programmatically.
  /// The handler is invoked on tear down of the test run.
  /// The default reporter fails in case of found leaks.
  ///
  /// Used to test leak tracking functionality.
  static LeaksCallback collectedLeaksReporter =
      (Leaks leaks) => expect(leaks, isLeakFree);

  /// Current configuration for leak tracking.
  ///
  /// Is used by `testWidgets` if configuration is not provided for a test.
  static LeakTesting settings = const LeakTesting._();

  /// Copies with [ignore] set to true.
  @useResult
  LeakTesting withIgnoredAll() => copyWith(ignore: true);

  /// Copies with [ignore] set to false.
  @useResult
  LeakTesting withTrackedAll() => copyWith(ignore: false);

  /// Copies with enabled collection of creation stack trace.
  ///
  /// Stack trace of the leaked object creation will be added to diagnostics.
  @useResult
  LeakTesting withCreationStackTrace() {
    return copyWith(
      leakDiagnosticConfig: leakDiagnosticConfig.copyWith(
        collectStackTraceOnStart: true,
      ),
    );
  }

  /// Copies with enabled collection of disposal stack trace.
  ///
  /// Stack trace of the leaked object disposal will be added to diagnostics.
  @useResult
  LeakTesting withDisposalStackTrace() {
    return copyWith(
      leakDiagnosticConfig: leakDiagnosticConfig.copyWith(
        collectStackTraceOnDisposal: true,
      ),
    );
  }

  /// Creates copy of [settings], that
  /// collects the retaining path for not GCed objects.
  @useResult
  LeakTesting withRetainingPath() {
    return copyWith(
      leakDiagnosticConfig: leakDiagnosticConfig.copyWith(
        collectRetainingPathForNotGCed: true,
      ),
    );
  }

  /// Returns copy of [settings] with extended ignore lists.
  ///
  /// In the result the ignored limit for a class is the
  /// maximum of two original ignored limits.
  /// Items in [classes] will be added to all ignore lists.
  ///
  /// Setting [createdByTestHelpers] to true may cause significant
  /// performance impact on the test run, caused by conversion of
  /// creation call stack to String.
  @useResult
  LeakTesting withIgnored({
    Map<String, int?> notGCed = const {},
    bool allNotGCed = false,
    Map<String, int?> notDisposed = const {},
    bool allNotDisposed = false,
    List<String> classes = const [],
    bool createdByTestHelpers = false,
    List<RegExp> testHelperExceptions = const [],
  }) {
    Map<String, int?> addClassesToMap(
      Map<String, int?> map,
      List<String> classes,
    ) {
      return {
        ...map,
        for (final c in classes) c: null,
      };
    }

    return copyWith(
      ignoredLeaks: IgnoredLeaks(
        experimentalNotGCed: ignoredLeaks.experimentalNotGCed.merge(
          IgnoredLeaksSet(
            byClass: addClassesToMap(notGCed, classes),
            ignoreAll: allNotGCed,
          ),
        ),
        notDisposed: ignoredLeaks.notDisposed.merge(
          IgnoredLeaksSet(
            byClass: addClassesToMap(notDisposed, classes),
            ignoreAll: allNotDisposed,
          ),
        ),
        createdByTestHelpers:
            ignoredLeaks.createdByTestHelpers || createdByTestHelpers,
        testHelperExceptions: [
          ...ignoredLeaks.testHelperExceptions,
          ...testHelperExceptions,
        ],
      ),
    );
  }

  /// Returns copy of [settings] with reduced ignore lists.
  ///
  /// Items in [classes] will be removed from all ignore lists.
  @useResult
  LeakTesting withTracked({
    List<String> experimentalNotGCed = const [],
    List<String> notDisposed = const [],
    List<String> classes = const [],
    bool experimentalAllNotGCed = false,
    bool allNotDisposed = false,
    bool createdByTestHelpers = false,
  }) {
    var newNotGCed = ignoredLeaks.experimentalNotGCed
        .track([...experimentalNotGCed, ...classes]);
    if (experimentalAllNotGCed) {
      newNotGCed = newNotGCed.copyWith(ignoreAll: false);
    }

    var newNotDisposed =
        ignoredLeaks.notDisposed.track([...notDisposed, ...classes]);
    if (allNotDisposed) {
      newNotDisposed = newNotDisposed.copyWith(ignoreAll: false);
    }

    final result = copyWith(
      ignoredLeaks: IgnoredLeaks(
        experimentalNotGCed: newNotGCed,
        notDisposed: newNotDisposed,
        createdByTestHelpers:
            ignoredLeaks.createdByTestHelpers && !createdByTestHelpers,
        testHelperExceptions: ignoredLeaks.testHelperExceptions,
      ),
    );
    return result;
  }

  /// Creates a copy of this object with the given fields replaced
  /// with the new values.
  @useResult
  LeakTesting copyWith({
    IgnoredLeaks? ignoredLeaks,
    LeakDiagnosticConfig? leakDiagnosticConfig,
    bool? ignore,
    MemoryBaselining? baselining,
  }) {
    return LeakTesting._(
      ignoredLeaks: ignoredLeaks ?? this.ignoredLeaks,
      leakDiagnosticConfig: leakDiagnosticConfig ?? this.leakDiagnosticConfig,
      ignore: ignore ?? this.ignore,
      baselining: baselining ?? this.baselining,
    );
  }

  /// If true, leak tracking is paused.
  final bool ignore;

  /// Leaks to ignore.
  final IgnoredLeaks ignoredLeaks;

  /// Defines which diagnostics information to collect.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;

  // TODO(polina-c): add documentation for [baselining].
  // https://github.com/flutter/devtools/issues/6266
  /// Settings to measure the test's memory footprint.
  final MemoryBaselining baselining;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is LeakTesting &&
        other.ignore == ignore &&
        other.ignoredLeaks == ignoredLeaks &&
        other.baselining == baselining &&
        other.leakDiagnosticConfig == leakDiagnosticConfig;
  }

  @override
  int get hashCode => Object.hash(
        ignore,
        ignoredLeaks,
        baselining,
        leakDiagnosticConfig,
      );
}
