// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:meta/meta.dart';

void _emptyLeakHandler(Leaks leaks) {}

/// Set of helper methods to adjust default leak tracker settings for tests.
///
/// Some methods modify [LeakTrackingForTests.settings], others return adjusted
/// copy of [LeakTrackingForTests.settings].
///
/// Use methods, which modify [LeakTrackingForTests.settings], to
/// change default settings for set of tests,
/// for example for package or folder (in flutter_test_config.dart) or
/// for library (in `setUpAll`).
///
/// Use methods that return adjusted [LeakTrackingForTests.settings]
/// to customize default for an individual test:
///
/// ```dart
/// testWidgets(
///     'initialTimerDuration falls within limit',
///     leakTracking: LeakTrackingForTests.withIgnoredLeaks(allNotGCed: true),
///     (WidgetTester tester) async {
///       ...
/// ```
///
/// If [LeakTrackingForTests.settings] are updated during a test run,
/// the updated settings will be used for the next test.
abstract final class LeakTrackingForTests {
  /// Current configuration for leak tracking.
  ///
  /// Is used by `testWidgets` if configuration is not provided for a test.
  static LeakTrackingForTestsSettings settings =
      const LeakTrackingForTestsSettings();

  /// Updates [settings] to pause leak tracking.
  static void ignoreAll() => settings = ignored();

  /// Updates [settings] to start leak tracking.
  static void track() => settings = tracked();

  /// Creates a copy of current settings with [LeakTrackingForTestsSettings.ignore] set to true.
  static LeakTrackingForTestsSettings ignored() =>
      settings.copyWith(ignore: true);

  /// Creates a copy of current settings with [LeakTrackingForTestsSettings.ignore] set to false.
  static LeakTrackingForTestsSettings tracked() =>
      settings.copyWith(ignore: false);

  /// Creates copy of current settings to debug notGCed leaks.
  static LeakTrackingForTestsSettings withCreationStackTrace() {
    return settings.copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectStackTraceOnStart: true,
      ),
    );
  }

  /// Creates copy of current settings to debug notDisposed leaks.
  static LeakTrackingForTestsSettings withDisposalStackTrace() {
    return settings.copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectStackTraceOnDisposal: true,
      ),
    );
  }

  /// Creates copy of current settings, that collects retaining path for not GCed objects.
  static LeakTrackingForTestsSettings withRetainingPath() {
    return settings.copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectRetainingPathForNotGCed: true,
      ),
    );
  }

  /// Adds certain classes and leak types to ignore lists in [settings].
  static void ignore({
    Map<String, int?> notGCed = const {},
    bool allNotGCed = false,
    Map<String, int?> notDisposed = const {},
    bool allNotDisposed = false,
    List<String> classes = const [],
  }) {
    settings = withIgnoredLeaks(
      notDisposed: notDisposed,
      notGCed: notGCed,
      allNotDisposed: allNotDisposed,
      allNotGCed: allNotGCed,
      classes: classes,
    );
  }

  /// Returns copy of [settings] with extended skip lists.
  ///
  /// In the result the skip limit for a class is maximum of two original skip limits.
  /// Items in [classes] will be added to all skip lists.
  static LeakTrackingForTestsSettings withIgnoredLeaks({
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

    return settings.copyWith(
      ignoredLeaks: IgnoredLeaks(
        notGCed: settings.ignoredLeaks.notGCed.merge(
          IgnoredLeaksSet(
            byClass: addClassesToMap(notGCed, classes),
            ignoreAll: allNotGCed,
          ),
        ),
        notDisposed: settings.ignoredLeaks.notDisposed.merge(
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
  static LeakTrackingForTestsSettings copyWithTrackedLeaks({
    List<String> notGCed = const [],
    List<String> notDisposed = const [],
    List<String> classes = const [],
  }) {
    final result = settings.copyWith(
      ignoredLeaks: IgnoredLeaks(
        notGCed: settings.ignoredLeaks.notGCed.track([...notGCed, ...classes]),
        notDisposed: settings.ignoredLeaks.notDisposed
            .track([...notDisposed, ...classes]),
      ),
    );
    return result;
  }

  /// Removes certain classes and leak types from ignore lists in [settings].
  ///
  /// Items in [classes] will be removed from all ignore lists.
  static void trackLeaks({
    List<String> notGCed = const [],
    List<String> notDisposed = const [],
    List<String> classes = const [],
  }) {
    settings = copyWithTrackedLeaks(
      notDisposed: notDisposed,
      notGCed: notGCed,
      classes: classes,
    );
  }
}

/// Leak tracking settings for tests.
///
/// Should be instantiated using static methods of [LeakTrackingForTests].
class LeakTrackingForTestsSettings {
  @visibleForTesting
  const LeakTrackingForTestsSettings({
    this.ignore = true,
    this.ignoredLeaks = const IgnoredLeaks(),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.failOnLeaksCollected = true,
    this.onLeaks = _emptyLeakHandler,
  });

  /// Creates a copy of this object with the given fields replaced
  /// with the new values.
  LeakTrackingForTestsSettings copyWith({
    IgnoredLeaks? ignoredLeaks,
    LeakDiagnosticConfig? leakDiagnosticConfig,
    bool? failOnLeaksCollected,
    LeaksCallback? onLeaks,
    MemoryBaselining? baselining,
    bool? ignore,
  }) {
    return LeakTrackingForTestsSettings(
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
