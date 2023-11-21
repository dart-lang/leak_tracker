// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:matcher/expect.dart';

void mayBeSetupLeakTrackingForTest(
  LeakTesting settings,
  String testDescription,
) {
  if (settings.ignore) return;

  if (!_checkPlatformAndMayBePrintWarning(
      platformName: defaultTargetPlatform.name, isBrowser: kIsWeb)) {
    return;
  }

  _setUpLeakTracking();

  final PhaseSettings phase = PhaseSettings(
    name: testDescription,
    leakDiagnosticConfig: settings.leakDiagnosticConfig,
    ignoredLeaks: settings.ignoredLeaks,
    baselining: settings.baselining,
    ignoreLeaks: settings.ignore,
  );

  LeakTracking.phase = phase;
}

void ignoreAllLeaks() {
  LeakTracking.phase = const PhaseSettings.ignored();
}

/// Should be invoked after execution of all tests to report found leaks.
Future<void> maybeTearDownLeakTracking() async {
  if (!LeakTracking.isStarted) {
    return;
  }

  MemoryAllocations.instance.removeListener(_dispatchFlutterEventToLeakTracker);

  LeakTracking.declareNotDisposedObjectsAsLeaks();
  await forceGC(fullGcCycles: defaultNumberOfGcCycles);
  final Leaks leaks = await LeakTracking.collectLeaks();
  LeakTracking.stop();

  if (leaks.total == 0) {
    return;
  }
  collectedLeaksReporter(leaks);
}

/// Handler for memory leaks found in tests.
///
/// Set it to analyse the leaks programmatically.
/// The handler is invoked on tear down of the test run.
/// The default reporter fails in case of found leaks.
///
/// Used to test leak tracking functionality.
LeaksCallback collectedLeaksReporter =
    (Leaks leaks) => expect(leaks, isLeakFree);

void _dispatchFlutterEventToLeakTracker(ObjectEvent event) {
  return LeakTracking.dispatchObjectEvent(event.toMap());
}

bool _notSupportedWarningPrinted = false;

/// Checks if platform supported and, if no, prints warning if the warning is needed.
///
/// Warning is printed one time if `LeakTracking.warnForNotSupportedPlatforms` is true.
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
    'To turn off this message, set `LeakTracking.warnForNotSupportedPlatforms` to false.',
  );

  return false;
}

void _setUpLeakTracking() {
  assert(!LeakTracking.isStarted);

  LeakTracking.phase = const PhaseSettings.ignored();
  LeakTracking.start(config: LeakTrackingConfig.passive());
  MemoryAllocations.instance.addListener(_dispatchFlutterEventToLeakTracker);
}
