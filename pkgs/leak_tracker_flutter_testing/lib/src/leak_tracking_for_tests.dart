// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';

import 'model.dart';

void _emptyLeakHandler(Leaks leaks) {}

/// Leak tracking settings for tests.
abstract class LeakTrackingForTests {
  static LeakTrackingForTestsSettings settings =
      LeakTrackingForTestsSettings._();

  static void pause() => settings = settings.copyWith(paused: true);
  static void start() => settings = settings.copyWith(paused: false);

  static LeakTrackingForTestsSettings debugNotGCed() {
    return settings.copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig.debugNotGCed(),
    );
  }

  static LeakTrackingForTestsSettings debugNotDisposed() {
    return settings.copyWith(
      leakDiagnosticConfig: const LeakDiagnosticConfig.debugNotDisposed(),
    );
  }

  static void skip({
    Map<String, int?> notGCed = const {},
    bool allNotGCed = false,
    Map<String, int?> notDisposed = const {},
    bool allNotDisposed = false,
    List<String> classes = const [],
  }) {
    settings = withSkipped(
      notDisposed: notDisposed,
      notGCed: notGCed,
      allNotDisposed: allNotDisposed,
      allNotGCed: allNotGCed,
      classes: classes,
    );
  }

  /// Returns [settings] with extended skip lists.
  ///
  /// In result the skip limit for a class is maximum of two original skip limits.
  /// Items in [classes] will be added to all skip lists.
  static LeakTrackingForTestsSettings withSkipped({
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
      return {...map}..addEntries(classes.map((c) => MapEntry(c, null)));
    }

    return settings.copyWith(
      leakSkipLists: LeakSkipLists(
        notGCed: settings.leakSkipLists.notGCed.merge(
          LeakSkipList(
            byClass: addClassesToMap(notGCed, classes),
            skipAll: allNotGCed,
          ),
        ),
        notDisposed: settings.leakSkipLists.notGCed.merge(
          LeakSkipList(
            byClass: addClassesToMap(notDisposed, classes),
            skipAll: allNotDisposed,
          ),
        ),
      ),
    );
  }

  /// Removes classes from leak skip lists.
  ///
  /// Items in [classes] will be removed from all skip lists.
  static LeakTrackingForTestsSettings withTracked({
    List<String> notGCed = const [],
    List<String> notDisposed = const [],
    List<String> classes = const [],
  }) {
    final result = settings.copyWith(
      leakSkipLists: LeakSkipLists(
        notGCed: settings.leakSkipLists.notGCed.track(notGCed).track(classes),
        notDisposed: settings.leakSkipLists.notDisposed
            .track(notDisposed)
            .track(classes),
      ),
    );
    return result;
  }

  /// Removes classes from leak skip lists.
  ///
  /// Items in [classes] will be removed from all skip lists.
  static void track({
    List<String> notGCed = const [],
    List<String> notDisposed = const [],
    List<String> classes = const [],
  }) {
    settings = withTracked(
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
  LeakTrackingForTestsSettings._({
    this.paused = true,
    this.leakSkipLists = const LeakSkipLists(),
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.failOnLeaks = true,
    this.onLeaks = _emptyLeakHandler,
  });

  LeakTrackingForTestsSettings copyWith({
    LeakSkipLists? leakSkipLists,
    LeakDiagnosticConfig? leakDiagnosticConfig,
    bool? failOnLeaks,
    LeaksCallback? onLeaks,
    MemoryBaselining? baselining,
    bool? paused,
  }) {
    return LeakTrackingForTestsSettings._(
      leakSkipLists: leakSkipLists ?? this.leakSkipLists,
      leakDiagnosticConfig: leakDiagnosticConfig ?? this.leakDiagnosticConfig,
      failOnLeaks: failOnLeaks ?? this.failOnLeaks,
      onLeaks: onLeaks ?? this.onLeaks,
      paused: paused ?? this.paused,
    );
  }

  /// If true, leak tracking is paused.
  final bool paused;

  final bool failOnLeaks;

  final LeaksCallback onLeaks;

  final LeakSkipLists leakSkipLists;

  /// Defines which disgnostics information to collect.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;
}
