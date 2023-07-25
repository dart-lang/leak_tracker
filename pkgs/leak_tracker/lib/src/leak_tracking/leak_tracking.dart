// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../leak_tracker.dart';
import '../shared/_primitives.dart';
import '../devtools_integration/_registration.dart';
import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_dispatcher.dart' as dispatcher;
import '_leak_reporter.dart';
import '_object_tracker.dart';
import 'model.dart';

abstract class LeakTracking {
  static LeakTracker? _leakTracker;

  /// Leak provider, used for integration with DevTools.
  ///
  /// It should be updated every time leak tracking is reconfigured.
  static final _leakProvider = ObjectRef<WeakReference<LeakProvider>?>(null);

  /// Enables leak tracking for the application.
  ///
  /// The leak tracking will function only for debug/profile/developer mode.
  /// See usage guidance at https://github.com/dart-lang/leak_tracker.
  ///
  /// If [resetIfAlreadyEnabled] is true and leak tracking is already on,
  /// the tracking will be reset with new configuration.
  ///
  /// If [resetIfAlreadyEnabled] is true and leak tracking is already on,
  /// [StateError] will be thrown.
  void enableLeakTracking({
    LeakTrackingConfiguration? config,
    bool resetIfAlreadyEnabled = false,
  }) {
    assert(() {
      final theConfig = config ??= const LeakTrackingConfiguration();
      if (_leakTracker != null) {
        if (!resetIfAlreadyEnabled) {
          throw StateError('Leak tracking is already enabled.');
        }
        disableLeakTracking();
      }

      final objectTracker = ObjectTracker(
        leakDiagnosticConfig: theConfig.leakDiagnosticConfig,
        disposalTime: theConfig.disposalTime,
        numberOfGcCycles: theConfig.numberOfGcCycles,
      );

      final leakChecker = LeakReporter(
        leakProvider: objectTracker,
        checkPeriod: theConfig.checkPeriod,
        onLeaks: theConfig.onLeaks,
        stdoutSink: theConfig.stdoutLeaks ? StdoutSummarySink() : null,
        devToolsSink: theConfig.notifyDevTools ? DevToolsSummarySink() : null,
      );

      _leakProvider.value = WeakReference(objectTracker);

      if (theConfig.notifyDevTools) {
        setupDevToolsIntegration(_leakProvider);
      } else {
        registerLeakTrackingServiceExtension();
      }
      return true;
    }());
  }

  /// Disables leak tracking for the application.
  ///
  /// See usage guidance at https://github.com/dart-lang/leak_tracker.
  void disableLeakTracking() {
    assert(() {
      _leakProvider.value?.dispose();
      _leakChecker?.dispose();
      _leakChecker = null;
      _objectTracker.value?.dispose();
      _objectTracker.value = null;

      return true;
    }());
  }
}
