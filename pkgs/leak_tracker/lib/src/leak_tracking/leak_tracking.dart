// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';

import '../devtools_integration/_registration.dart';
import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_baseliner.dart';
import '_leak_tracker.dart';
import '_primitives/_dispatcher.dart' as dispatcher;
import '_primitives/model.dart';

final _log = Logger('leak_tracking.dart');

/// Provides leak tracking functionality.
abstract class LeakTracking {
  static Baseliner? _baseliner;

  static LeakTracker? _leakTracker;

  /// Leak provider, used for integration with DevTools.
  ///
  /// It's value should be updated every time leak tracking is reconfigured.
  static final _leakProvider = ObjectRef<WeakReference<LeakProvider>?>(null);

  /// If true, a warning will be printed when leak tracking is
  /// requested for a non-supported platform.
  static bool warnForUnsupportedPlatforms = true;

  /// Settings for leak tracking phase.
  ///
  /// Can be modified before leak tracking is started and while it
  /// is in process.
  ///
  /// Objects will be assigned to the phase at the moment of
  /// tracking start. Name of the phase will be mentioned in the leak report.
  static PhaseSettings get phase => _phase.value;
  static set phase(PhaseSettings value) {
    if (_phase.value == value) return;
    _baseliner = Baseliner.finishOldAndStartNew(_baseliner, value.baselining);
    _phase.value = value;
  }

  static final _phase = ObjectRef(const PhaseSettings());

  /// Returns true if leak tracking is configured.
  static bool get isStarted => _leakTracker != null;

  /// Configures leak tracking for the application.
  ///
  /// The leak tracking will function only for debug/profile/developer mode.
  /// See usage guidance at https://github.com/dart-lang/leak_tracker.
  ///
  /// If [resetIfAlreadyStarted] is true and leak tracking is already on,
  /// the tracking will be reset with new configuration.
  ///
  /// If [resetIfAlreadyStarted] is false and leak tracking is already on,
  /// [StateError] will be thrown.
  static void start({
    LeakTrackingConfig config = const LeakTrackingConfig(),
    bool resetIfAlreadyStarted = false,
  }) {
    assert(() {
      if (_leakTracker != null) {
        if (!resetIfAlreadyStarted) {
          throw StateError('Leak tracking is already enabled.');
        }
        stop();
      }

      final leakTracker = _leakTracker = LeakTracker(config, _phase);
      _leakProvider.value = WeakReference(leakTracker.objectTracker);

      if (config.notifyDevTools) {
        // While [leakTracker] will push summary leak notifications to DevTools,
        // DevTools may request leak details from the application via integration.
        // That's why it needs [_leakProvider].
        initializeDevToolsIntegration(_leakProvider);
      } else {
        registerLeakTrackingServiceExtension();
      }
      _log.info('started leak tracking');
      return true;
    }());
  }

  /// Stops leak tracking for the application.
  ///
  /// See usage guidance at https://github.com/dart-lang/leak_tracker.
  static void stop() {
    assert(() {
      _leakTracker?.dispose();
      _leakTracker = null;
      Baseliner.finishOldAndStartNew(_baseliner, null);
      _log.info('stopped leak tracking');
      return true;
    }());
  }

  /// Dispatches an object event to the leak tracker.
  ///
  /// Consumes the MemoryAllocations event format:
  /// https://github.com/flutter/flutter/blob/a479718b02a818fb4ac8d4900bf08ca389cd8e7d/packages/flutter/lib/src/foundation/memory_allocations.dart#L51
  static void dispatchObjectEvent(Map<Object, Map<String, Object>> event) {
    assert(() {
      dispatcher.dispatchObjectEvent(
        event,
        onStartTracking: dispatchObjectCreated,
        onDispatchDisposal: dispatchObjectDisposed,
      );
      return true;
    }());
  }

  /// Dispatches object creation to the leak tracker.
  ///
  /// Use [context] to provide additional information, that may help in leek troubleshooting.
  /// The value must be serializable.
  static void dispatchObjectCreated({
    required String library,
    required String className,
    required Object object,
    Map<String, dynamic>? context,
  }) {
    assert(() {
      _baseliner?.takeSample();
      _leakTracker?.objectTracker.startTracking(
        object,
        context: context,
        trackedClass:
            fullClassName(library: library, shortClassName: className),
        phase: _phase.value,
      );

      return true;
    }());
  }

  /// Dispatches object disposal to the leak tracker.
  ///
  /// See [dispatchObjectCreated] for parameters documentation.
  static void dispatchObjectDisposed({
    required Object object,
    Map<String, dynamic>? context,
  }) {
    assert(() {
      _baseliner?.takeSample();
      _leakTracker?.objectTracker.dispatchDisposal(object, context: context);
      return true;
    }());
  }

  /// Dispatches additional context information to the leak tracker.
  ///
  /// See [dispatchObjectCreated] for parameters documentation.
  static void dispatchObjectTrace({
    required Object object,
    Map<String, dynamic>? context,
  }) {
    assert(() {
      _baseliner?.takeSample();
      _leakTracker?.objectTracker.addContext(object, context: context);
      return true;
    }());
  }

  /// Checks for leaks and outputs [LeakSummary] as configured.
  static Future<LeakSummary> checkLeaks() async {
    Future<LeakSummary>? result;

    assert(() {
      result = _leakTracker?.leakReporter.checkLeaks();
      return true;
    }());

    return await (result ?? Future.value(LeakSummary({})));
  }

  /// Returns details of the leaks collected since last invocation.
  ///
  /// The same object may be reported as leaked twice: first
  /// as non GCed, and then as GCed late.
  ///
  /// Should be invoked before [stop] to obtain the leaks.
  static Future<Leaks> collectLeaks() async {
    Future<Leaks>? result;

    assert(() {
      result = _leakTracker?.objectTracker.collectLeaks();
      return true;
    }());

    return await (result ?? Future.value(Leaks({})));
  }

  /// Checks for new not-GCed leaks.
  ///
  /// Invoke this method to detect the leaks earlier, when
  /// the leaked objects are not GCed yet,
  /// to obtain retaining path.
  static Future<void> checkNotGCed() async {
    Future<void>? result;

    assert(() {
      result = _leakTracker?.objectTracker.checkNonGCed();
      return true;
    }());

    await (result ?? Future.value());
  }
}
