// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  LeakTracking.phase = const PhaseSettings.ignored();
  LeakTracking.start(config: LeakTrackingConfig.passive());

  MemoryAllocations.instance.addListener(_flutterEventToLeakTracker);
}

bool _stopConfiguringTearDown = false;

/// Sets [tearDownAll] to tear down leak tracking if it is started.
///
/// [configureOnce] is true tear down will be created just once,
/// not for every test.
/// Multiple [tearDownAll] is needed to handle test groups that have
/// own [tearDownAll].
///
/// Single tear down is needed to test leak tracking.
@visibleForTesting
void configureLeakTrackingTearDown({
  LeaksCallback? onLeaks,
  bool configureOnce = false,
}) {
  if (_isPlatformSupported && !_stopConfiguringTearDown) {
    tearDownAll(() async {
      if (LeakTracking.isStarted) {
        await _tearDownTestingWithLeakTracking(onLeaks);
      }
    });
  }
  if (configureOnce) _stopConfiguringTearDown = true;
}

Future<void> _tearDownTestingWithLeakTracking(LeaksCallback? onLeaks) async {
  if (!LeakTracking.isStarted) return;
  if (!_isPlatformSupported) return;
  MemoryAllocations.instance.removeListener(_flutterEventToLeakTracker);

  LeakTracking.declareNotDisposedObjectsAsLeaks();
  await forceGC(fullGcCycles: defaultNumberOfGcCycles);
  final leaks = await LeakTracking.collectLeaks();

  LeakTracking.stop();

  if (leaks.total == 0) return;
  if (onLeaks == null) {
    expect(leaks, isLeakFree);
  } else {
    onLeaks(leaks);
  }
}

// TODO(polina-c): retire this function after migration to `testWidgets`.
// https://github.com/flutter/flutter/issues/135856

/// Wrapper for [testWidgets] with memory leak tracking.
///
/// The test will fail if instrumented objects in [callback] are
/// garbage collected without being disposed or not garbage
/// collected soon after disposal.
///
/// [testExecutableWithLeakTracking] must be invoked for this test run.
///
/// More about leak tracking: https://github.com/dart-lang/leak_tracker.
@isTest
void testWidgetsWithLeakTracking(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  LeakTesting? leakTesting,
}) {
  configureLeakTrackingTearDown();

  Future<void> wrappedCallBack(WidgetTester tester) async {
    final settings = leakTesting ?? LeakTesting.settings;

    final phase = PhaseSettings(
      name: description,
      leakDiagnosticConfig: settings.leakDiagnosticConfig,
      ignoredLeaks: settings.ignoredLeaks,
      baselining: const MemoryBaselining.none(),
      ignoreLeaks: settings.ignore,
    );

    if (!LeakTracking.isStarted) _setUpTestingWithLeakTracking();
    LeakTracking.phase = phase;
    await callback(tester);
    LeakTracking.phase = const PhaseSettings.ignored();
  }

  // Temporarily turn off leak tracking, so that `testWidgests` does not track leaks in addition.
  final originalGlobalSettings = LeakTesting.settings;
  LeakTesting.settings = LeakTesting.settings.withIgnoredAll();

  try {
    testWidgets(
      description,
      wrappedCallBack,
      skip: skip,
      timeout: timeout,
      semanticsEnabled: semanticsEnabled,
      variant: variant,
      tags: tags,
    );
  } finally {
    LeakTesting.settings = originalGlobalSettings;
  }
}

bool _notSupportedWarningPrinted = false;
bool get _isPlatformSupported => !kIsWeb;
void _printPlatformWarningIfNeeded() {
  if (kIsWeb) {
    final bool shouldPrintWarning = !_notSupportedWarningPrinted &&
        LeakTracking.warnForUnsupportedPlatforms;
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
