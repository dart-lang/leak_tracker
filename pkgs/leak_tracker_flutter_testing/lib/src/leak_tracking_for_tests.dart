// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:meta/meta.dart';

void _emptyLeakHandler(Leaks leaks) {}

/// Leak tracker settings for tests.
///
/// Modify [LeakTrackingForTests.settings], to
/// change default settings for tests that do not set leak tracking configuration,
/// for package or folder in flutter_test_config.dart and for
/// a test file in `setUpAll`.
///
/// If you update the settings for a group, remember the original value to a local variable
/// and restore it in `tearDownAll` for the group.
///
/// Use methods that return adjusted [LeakTrackingForTests.settings]
/// to customize default for an individual test:
///
/// ```dart
/// testWidgets(
///     'initialTimerDuration falls within limit',
///     leakTracking: LeakTrackingForTests.withIgnoredAll(),
///     (WidgetTester tester) async {
///       ...
/// ```
///
/// If [LeakTrackingForTests.settings] are updated during a test run,
/// the updated settings will be used for the next test.
class LeakTrackingForTests {
  @visibleForTesting
  const LeakTrackingForTests({
    this.ignore = true,
    this.ignoredLeaks = const IgnoredLeaks(),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.failOnLeaksCollected = true,
    this.onLeaks = _emptyLeakHandler,
  });

  /// Current configuration for leak tracking.
  ///
  /// Is used by `testWidgets` if configuration is not provided for a test.
  static LeakTrackingForTests settings = const LeakTrackingForTests();

  /// Copies with [ignore] set to true.
  @useResult
  LeakTrackingForTests withIgnoredAll() => copyWith(ignore: true);

  /// Copies with [ignore] set to false.
  @useResult
  LeakTrackingForTests withTrackedAll() => copyWith(ignore: false);

  /// Copies with enabled collection of creation stack trace.
  ///
  /// Stack trace of the leaked object creation will be added to diagnostics.
  @useResult
  LeakTrackingForTests withCreationStackTrace() {
    return copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectStackTraceOnStart: true,
      ),
    );
  }

  /// Copies with enabled collection of disposal stack trace.
  ///
  /// Stack trace of the leaked object disposal will be added to diagnostics.
  @useResult
  LeakTrackingForTests withDisposalStackTrace() {
    return copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectStackTraceOnDisposal: true,
      ),
    );
  }

  /// Creates copy of [settings], that collects retaining path for not GCed objects.
  @useResult
  LeakTrackingForTests withRetainingPath() {
    return copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectRetainingPathForNotGCed: true,
      ),
    );
  }

  /// Returns copy of [settings] with extended skip lists.
  ///
  /// In the result the skip limit for a class is maximum of two original skip limits.
  /// Items in [classes] will be added to all skip lists.
  @useResult
  LeakTrackingForTests withIgnored({
    Map<String, int?> notGCed = const {},
    bool allNotGCed = false,
    Map<String, int?> notDisposed = const {},
    bool allNotDisposed = false,
    List<String> classes = const [],
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
        notGCed: ignoredLeaks.notGCed.merge(
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
      ),
    );
  }

  /// Returns copy of [settings] with reduced ignore lists.
  ///
  /// Items in [classes] will be removed from all ignore lists.
  @useResult
  LeakTrackingForTests withTracked({
    List<String> notGCed = const [],
    List<String> notDisposed = const [],
    List<String> classes = const [],
  }) {
    final result = copyWith(
      ignoredLeaks: IgnoredLeaks(
        notGCed: ignoredLeaks.notGCed.track([...notGCed, ...classes]),
        notDisposed:
            ignoredLeaks.notDisposed.track([...notDisposed, ...classes]),
      ),
    );
    return result;
  }

  /// Creates a copy of this object with the given fields replaced
  /// with the new values.
  @useResult
  LeakTrackingForTests copyWith({
    IgnoredLeaks? ignoredLeaks,
    LeakDiagnosticConfig? leakDiagnosticConfig,
    bool? failOnLeaksCollected,
    LeaksCallback? onLeaks,
    bool? ignore,
  }) {
    return LeakTrackingForTests(
      ignoredLeaks: ignoredLeaks ?? this.ignoredLeaks,
      leakDiagnosticConfig: leakDiagnosticConfig ?? this.leakDiagnosticConfig,
      failOnLeaksCollected: failOnLeaksCollected ?? this.failOnLeaksCollected,
      onLeaks: onLeaks ?? this.onLeaks,
      ignore: ignore ?? this.ignore,
    );
  }

  /// If true, leak tracking is paused.
  final bool ignore;

  /// If true, tests will fail on leaks.
  ///
  /// Set to true to test that tests collect expected leaks.
  final bool failOnLeaksCollected;

  /// Callback to invoke before the test fails when [failOnLeaksCollected] is true and if leaks were found.
  final LeaksCallback onLeaks;

  /// Leaks to ignore.
  final IgnoredLeaks ignoredLeaks;

  /// Defines which diagnostics information to collect.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;
}
