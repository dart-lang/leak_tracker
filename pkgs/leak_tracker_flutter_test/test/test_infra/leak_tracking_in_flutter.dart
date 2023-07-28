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

void setUpTestingWithLeakTracking() {
  _printPlatformWarningIfNeeded();
  if (!_isPlatformSupported) return;

  LeakTracking.start(config: LeakTrackingConfig.passive());

  MemoryAllocations.instance.addListener(_flutterEventToLeakTracker);
}

Future<void> tearDownTestingWithLeakTracking() async {
  if (!_isPlatformSupported) return Future<void>.value();

  MemoryAllocations.instance.removeListener(_flutterEventToLeakTracker);
  await forceGC(fullGcCycles: 3);
  final leaks = await LeakTracking.collectLeaks();

  LeakTracking.stop();

  expect(leaks, isLeakFree);
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
