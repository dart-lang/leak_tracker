// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

/// Makes sure leak tracking is set up for a test.
///
/// If `settings.ignore` is true, the method is noop.
/// If leak tracking is not started, starts it.
/// Configures `LeakTracking.phase` to match [settings].
void maybeSetupLeakTrackingForTest(
  LeakTesting? settings,
  String testDescription,
) {
  if (!LeakTesting.enabled) return;

  final leakTesting = settings ?? LeakTesting.settings;
  if (leakTesting.ignore) return;

  if (!_checkPlatformAndMayBePrintWarning(
      platformName: defaultTargetPlatform.name, isBrowser: kIsWeb)) {
    return;
  }

  _maybeStartLeakTracking();

  final phase = PhaseSettings(
    name: testDescription,
    leakDiagnosticConfig: leakTesting.leakDiagnosticConfig,
    ignoredLeaks: leakTesting.ignoredLeaks,
    baselining: leakTesting.baselining,
    ignoreLeaks: leakTesting.ignore,
  );

  LeakTracking.phase = phase;
}

/// If leak tracking is enabled, stops it and
/// declares notDisposed objects as leaks.
void maybeTearDownLeakTrackingForTest() {
  if (!LeakTesting.enabled ||
      !LeakTracking.isStarted ||
      LeakTracking.phase.ignoreLeaks) return;
  LeakTracking.phase = const PhaseSettings.ignored();
}

/// Should be invoked after execution of all tests to report found leaks.
///
/// Is noop if leak tracking is not started.
Future<void> maybeTearDownLeakTrackingForAll() async {
  if (!LeakTesting.enabled || !LeakTracking.isStarted) {
    // Reporter is invoked so that tests can verify the number of
    // collected leaks is as expected.
    LeakTesting.collectedLeaksReporter(Leaks({}));
    return;
  }

  // The listener is not added/removed for each test,
  // because GC may happen after test is complete.
  MemoryAllocations.instance.removeListener(_dispatchFlutterEventToLeakTracker);
  await forceGC(fullGcCycles: defaultNumberOfGcCycles);
  LeakTracking.declareNotDisposedObjectsAsLeaks();
  final leaks = await LeakTracking.collectLeaks();
  LeakTracking.stop();

  LeakTesting.collectedLeaksReporter(leaks);
}

void _dispatchFlutterEventToLeakTracker(ObjectEvent event) {
  return LeakTracking.dispatchObjectEvent(event.toMap());
}

bool _notSupportedWarningPrinted = false;

/// Checks if platform supported and, if no,
/// prints warning if the warning is needed.
///
/// Warning is printed one time if
/// `LeakTracking.warnForNotSupportedPlatforms` is `true`.
bool _checkPlatformAndMayBePrintWarning(
    {required String platformName, required bool isBrowser}) {
  final isSupported = !isBrowser;

  if (isSupported) return true;

  final shouldPrintWarning =
      LeakTracking.warnForUnsupportedPlatforms && !_notSupportedWarningPrinted;

  if (!shouldPrintWarning) return false;

  _notSupportedWarningPrinted = true;
  debugPrint(
    "Leak tracking is not supported on the platform '$platformName'.\n"
    'To turn off this message, set '
    '`LeakTracking.warnForNotSupportedPlatforms` to false.',
  );

  return false;
}

/// Starts leak tracking with all leaks ignored.
void _maybeStartLeakTracking() {
  if (LeakTracking.isStarted) return;

  LeakTracking.phase = const PhaseSettings.ignored();
  LeakTracking.start(config: LeakTrackingConfig.passive());
  MemoryAllocations.instance.addListener(_dispatchFlutterEventToLeakTracker);
}
