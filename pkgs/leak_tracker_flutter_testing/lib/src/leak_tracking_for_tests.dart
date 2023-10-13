// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:meta/meta.dart';

void _emptyLeakHandler(Leaks leaks) {}

/// Leak tracking settings and helper methods for tests.
abstract class LeakTrackingForTests {
  /// Current configuration for leak tracking.
  static LeakTrackingForTestsSettings settings = LeakTrackingForTestsSettings();

  /// Updates [settings] to pause leak tracking.
  static void pause() => settings = settings.copyWith(paused: true);

  /// Updates [settings] to start leak tracking.
  static void start() => settings = settings.copyWith(paused: false);

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

  /// Adds certain classes and leak types to skip lists in [settings].
  static void skip({
    Map<String, int?> notGCed = const {},
    bool allNotGCed = false,
    Map<String, int?> notDisposed = const {},
    bool allNotDisposed = false,
    List<String> classes = const [],
  }) {
    settings = copyWithSkippedLeaks(
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
  static LeakTrackingForTestsSettings copyWithSkippedLeaks({
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
      skippedLeaks: SkippedLeaks(
        notGCed: settings.skippedLeaks.notGCed.merge(
          LeakSkipSet(
            byClass: addClassesToMap(notGCed, classes),
            skipAll: allNotGCed,
          ),
        ),
        notDisposed: settings.skippedLeaks.notDisposed.merge(
          LeakSkipSet(
            byClass: addClassesToMap(notDisposed, classes),
            skipAll: allNotDisposed,
          ),
        ),
      ),
    );
  }

  /// Returns copy of [settings] with reduced skip lists.
  ///
  /// Items in [classes] will be removed from all skip lists.
  static LeakTrackingForTestsSettings copyWithTrackedLeaks({
    List<String> notGCed = const [],
    List<String> notDisposed = const [],
    List<String> classes = const [],
  }) {
    final result = settings.copyWith(
      skippedLeaks: SkippedLeaks(
        notGCed: settings.skippedLeaks.notGCed.track([...notGCed, ...classes]),
        notDisposed: settings.skippedLeaks.notDisposed
            .track([...notDisposed, ...classes]),
      ),
    );
    return result;
  }

  /// Removes certain classes and leak types from skip lists in [settings].
  ///
  /// Items in [classes] will be removed from all skip lists.
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
  LeakTrackingForTestsSettings({
    this.paused = true,
    this.skippedLeaks = const SkippedLeaks(),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.failOnLeaksCollected = true,
    this.onLeaks = _emptyLeakHandler,
  });

  /// Creates a copy of this object with the given fields replaced
  /// with the new values.
  LeakTrackingForTestsSettings copyWith({
    SkippedLeaks? skippedLeaks,
    LeakDiagnosticConfig? leakDiagnosticConfig,
    bool? failOnLeaks,
    LeaksCallback? onLeaks,
    MemoryBaselining? baselining,
    bool? paused,
  }) {
    return LeakTrackingForTestsSettings(
      skippedLeaks: skippedLeaks ?? this.skippedLeaks,
      leakDiagnosticConfig: leakDiagnosticConfig ?? this.leakDiagnosticConfig,
      failOnLeaksCollected: failOnLeaks ?? this.failOnLeaksCollected,
      onLeaks: onLeaks ?? this.onLeaks,
      paused: paused ?? this.paused,
    );
  }

  /// If true, leak tracking is paused.
  final bool paused;

  /// If true, tests will fail on leaks.
  ///
  /// Set to true to test that tests collect expected leaks.
  final bool failOnLeaksCollected;

  /// Callback to invoke before the test fails when [failOnLeaksCollected] is true and if leaks were found.
  final LeaksCallback onLeaks;

  /// Leaks to skip.
  final SkippedLeaks skippedLeaks;

  /// Defines which diagnostics information to collect.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;
}
