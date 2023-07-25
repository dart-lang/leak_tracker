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
import '_leak_tracker.dart';
import '_object_tracker.dart';
import 'model.dart';

abstract class LeakTracking {
  static LeakTracker? _leakTracker;

  /// Leak provider, used for integration with DevTools.
  ///
  /// It's value should be updated every time leak tracking is reconfigured.
  static final _leakProvider = ObjectRef<WeakReference<LeakProvider>?>(null);

  static bool get isEnabled => _leakTracker != null;

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
  static void enableLeakTracking({
    LeakTrackingConfiguration config = const LeakTrackingConfiguration(),
    bool resetIfAlreadyEnabled = false,
  }) {
    assert(() {
      if (_leakTracker != null) {
        if (!resetIfAlreadyEnabled) {
          throw StateError('Leak tracking is already enabled.');
        }
        disableLeakTracking();
      }

      final leakTracker = _leakTracker = LeakTracker(config);
      _leakProvider.value = WeakReference(leakTracker.objectTracker);

      if (config.notifyDevTools) {
        // While [leakTracker] will push summary leak notifications to DevTools,
        // DevTools may request leak details from the application via integration.
        // That's why it needs [_leakProvider].
        initializeDevToolsIntegration(_leakProvider);
      } else {
        registerLeakTrackingServiceExtension();
      }
      return true;
    }());
  }

  /// Disables leak tracking for the application.
  ///
  /// See usage guidance at https://github.com/dart-lang/leak_tracker.
  static void disableLeakTracking() {
    assert(() {
      _leakTracker?.dispose();
      _leakTracker = null;
      return true;
    }());
  }
}
