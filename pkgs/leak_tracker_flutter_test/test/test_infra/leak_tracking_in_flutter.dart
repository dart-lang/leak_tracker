// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Content of this file is mirror of
// https://github.com/flutter/flutter/blob/master/packages/flutter/test/foundation/leak_tracking.dart
// to test that a new version work well for Flutter Framework, before it upgrades to the version.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:meta/meta.dart';

void _flutterEventToLeakTracker(ObjectEvent event) {
  return LeakTracking.dispatchObjectEvent(event.toMap());
}

void _setUpTestingWithLeakTracking() {
  _printPlatformWarningIfNeeded();
  if (!_isPlatformSupported) return;

  LeakTracking.start(config: LeakTrackingConfig.passive());

  MemoryAllocations.instance.addListener(_flutterEventToLeakTracker);
}

bool _tearDownConfigured = false;

void configureLeakTrackingTearDown({
  LeaksCallback? onLeaks,
}) {
  if (_tearDownConfigured) {
    throw StateError('Leak tracking tear down is already configured.');
  }
  if (_isPlatformSupported) {
    tearDownAll(() async => await _tearDownTestingWithLeakTracking(onLeaks));
  }
  _tearDownConfigured = true;
}

Future<void> _tearDownTestingWithLeakTracking(LeaksCallback? onLeaks) async {
  if (!LeakTracking.isStarted) return;
  if (!_isPlatformSupported) return;

  MemoryAllocations.instance.removeListener(_flutterEventToLeakTracker);
  await forceGC(fullGcCycles: 3);
  final leaks = await LeakTracking.collectLeaks();

  LeakTracking.stop();

  if (leaks.total == 0) return;
  if (onLeaks == null) {
    expect(leaks, isLeakFree);
  } else {
    onLeaks(leaks);
  }
}

/// Wrapper for [testWidgets] with memory leak tracking.
///
/// The test will fail if instrumented objects in [callback] are
/// garbage collected without being disposed or not garbage
/// collected soon after disposal.
///
/// [testExecutableWithLeakTracking] must be invoked
/// for this test run.
///
/// More about leak tracking:
/// https://github.com/dart-lang/leak_tracker.
@isTest
void testWidgetsWithLeakTracking(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  PhaseSettings? phase,
}) {
  assert(
    phase?.name == null && (phase?.isPaused ?? false) == false,
    'Use `PhaseSettings.test()` to create phase for a test.',
  );

  if (!_tearDownConfigured) configureLeakTrackingTearDown();
  if (!LeakTracking.isStarted) _setUpTestingWithLeakTracking();

  Future<void> wrappedCallBack(WidgetTester tester) async {
    LeakTracking.phase = PhaseSettings.withName(
      phase ?? const PhaseSettings.test(),
      name: description,
    );

    if (!LeakTracking.isStarted) {
      throw StateError(
        '`setUpTestingWithLeakTracking` must be invoked in setUpAll to run tests with leak tracking.',
      );
    }

    await callback(tester);

    LeakTracking.phase = const PhaseSettings.paused();
  }

  testWidgets(
    description,
    wrappedCallBack,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
  );
}

bool _notSupportedWarningPrinted = false;
bool get _isPlatformSupported => !kIsWeb;
void _printPlatformWarningIfNeeded() {
  if (kIsWeb) {
    final bool shouldPrintWarning = !_notSupportedWarningPrinted &&
        LeakTracking.warnForNotSupportedPlatforms;
    if (shouldPrintWarning) {
      _notSupportedWarningPrinted = true;
      debugPrint(
        'Leak tracking is not supported on web platform.\nTo turn off this message, set `LeakTracking.warnForNotSupportedPlatforms` to false.',
      );
    }
    return;
  }
  assert(_isPlatformSupported);
}

/// Configuration for leak tracking in unit tests.
///
/// Customized configuration is needed only for test debugging,
/// not for regular test runs.
// TODO(polina-c): update helpers to respect allow lists defined in this class
// https://github.com/flutter/devtools/issues/5606
class LeakTrackingTestConfig {
  /// Creates a new instance of [LeakTrackingTestConfig].
  const LeakTrackingTestConfig({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// Creates a new instance of [LeakTrackingTestConfig] for debugging leaks.
  ///
  /// This configuration will collect stack traces on start and disposal,
  /// and retaining path for notGCed objects.
  LeakTrackingTestConfig.debug({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectStackTraceOnStart: true,
      collectStackTraceOnDisposal: true,
      collectRetainingPathForNonGCed: true,
    ),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// Creates a new instance of [LeakTrackingTestConfig] to collect retaining path.
  ///
  /// This configuration will not collect stack traces,
  /// and will collect retaining path for notGCed objects.
  LeakTrackingTestConfig.retainingPath({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectRetainingPathForNonGCed: true,
    ),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// When to collect stack trace information.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;

  /// Handler to obtain details about collected leaks.
  ///
  /// Use the handler to process the collected leak
  /// details programmatically.
  final LeaksCallback? onLeaks;

  /// If true, the test will fail if leaks are found.
  ///
  /// If false, the test will not fail if leaks are
  /// found to allow for analyzing leaks after the test completes.
  final bool failTestOnLeaks;

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
}

/// Runs [callback] with leak tracking.
///
/// Wrapper for [withLeakTracking] with Flutter specific functionality.
///
/// The method will fail if wrapped code contains memory leaks.
///
/// See details in documentation for `withLeakTracking` at
/// https://github.com/dart-lang/leak_tracker/blob/main/lib/src/orchestration.dart#withLeakTracking
///
/// The Flutter related enhancements are:
/// 1. Listens to [MemoryAllocations] events.
/// 2. Uses `tester.runAsync` for leak detection if [tester] is provided.
///
/// Pass [config] to troubleshoot or exempt leaks. See [LeakTrackingTestConfig]
/// for details.
Future<void> withFlutterLeakTracking(
  DartAsyncCallback callback,
  WidgetTester tester,
  LeakTrackingTestConfig config,
) async {
  // Leak tracker does not work for web platform.
  if (kIsWeb) {
    final bool shouldPrintWarning = !_notSupportedWarningPrinted &&
        LeakTracking.warnForNotSupportedPlatforms;
    if (shouldPrintWarning) {
      _notSupportedWarningPrinted = true;
      debugPrint(
        'Leak tracking is not supported on web platform.\nTo turn off this message, set `LeakTracking.warnForNotSupportedPlatforms` to false.',
      );
    }
    await callback();
    return;
  }

  void flutterEventToLeakTracker(ObjectEvent event) {
    return LeakTracking.dispatchObjectEvent(event.toMap());
  }

  return TestAsyncUtils.guard<void>(() async {
    MemoryAllocations.instance.addListener(flutterEventToLeakTracker);
    Future<void> asyncCodeRunner(DartAsyncCallback action) async =>
        tester.runAsync(action);

    try {
      Leaks leaks = await withLeakTracking(
        callback,
        asyncCodeRunner: asyncCodeRunner,
        leakDiagnosticConfig: config.leakDiagnosticConfig,
        shouldThrowOnLeaks: false,
      );

      leaks = LeakCleaner(config).clean(leaks);

      if (leaks.total > 0) {
        config.onLeaks?.call(leaks);
        if (config.failTestOnLeaks) {
          expect(leaks, isLeakFree);
        }
      }
    } finally {
      MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
    }
  });
}

/// Cleans leaks that are allowed by [config].
class LeakCleaner {
  LeakCleaner(this.config);

  final LeakTrackingTestConfig config;

  Leaks clean(Leaks leaks) {
    final Leaks result = Leaks(<LeakType, List<LeakReport>>{
      for (LeakType leakType in leaks.byType.keys)
        leakType: leaks.byType[leakType]!
            .where((LeakReport leak) => _shouldReportLeak(leakType, leak))
            .toList(),
    });
    return result;
  }

  /// Returns true if [leak] should be reported as failure.
  bool _shouldReportLeak(LeakType leakType, LeakReport leak) {
    switch (leakType) {
      case LeakType.notDisposed:
        return !config.notDisposedAllowList.containsKey(leak.type);
      case LeakType.notGCed:
      case LeakType.gcedLate:
        return !config.notGCedAllowList.containsKey(leak.type);
    }
  }
}
