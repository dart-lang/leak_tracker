// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Content of this file is copied from
// https://github.com/flutter/flutter/blob/master/packages/flutter/test/foundation/leak_tracking.dart
// to test that new versions work well for Flutter Framework.
// TODO(polina-c): This code should be removed after `testWidgets` start supporting leak tracking.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:meta/meta.dart';

/// Wrapper for [testWidgets] with memory leak tracking.
///
/// The method will fail if instrumented objects in [callback] are
/// garbage collected without being disposed.
///
/// More about leak tracking:
/// https://github.com/dart-lang/leak_tracker.
///
/// See https://github.com/flutter/devtools/issues/3951 for plans
/// on leak tracking.
@isTest
void testWidgetsWithLeakTracking(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  LeakTrackingTestConfig? leakTrackingTestConfig,
}) {
  final config = leakTrackingTestConfig ??
      (LeakTrackerGlobalFlags.collectDebugInformationForLeaks
          ? LeakTrackingTestConfig.debug()
          : const LeakTrackingTestConfig());

  Future<void> wrappedCallback(WidgetTester tester) async {
    await withFlutterLeakTracking(
      () async => callback(tester),
      tester,
      config,
    );
  }

  testWidgets(
    description,
    wrappedCallback,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
  );
}

bool _webWarningPrinted = false;

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
    final bool shouldPrintWarning = !_webWarningPrinted &&
        LeakTrackerGlobalFlags.warnForNonSupportedPlatforms;
    if (shouldPrintWarning) {
      _webWarningPrinted = true;
      debugPrint(
        'Leak tracking is not supported on web platform.\nTo turn off this message, set `LeakTrackerGlobalFlags.warnForNonSupportedPlatforms` to false.',
      );
    }
    await callback();
    return;
  }

  void flutterEventToLeakTracker(ObjectEvent event) {
    return dispatchObjectEvent(event.toMap());
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
