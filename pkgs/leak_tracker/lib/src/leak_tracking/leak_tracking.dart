// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_baseliner.dart';
import '_leak_tracker.dart';
import 'primitives/_dispatcher.dart' as dispatcher;
import 'primitives/model.dart';

/// Provides leak tracking functionality.
abstract class LeakTracking {
  static Baseliner? _baseliner;

  static LeakTracker? _leakTracker;

  /// If true, a warning will be printed when leak tracking is
  /// requested for a non-supported platform.
  static bool warnForUnsupportedPlatforms = true;

  /// Customized link to documentation on how to troubleshoot leaks.
  ///
  /// Used to provide a link to the user in the generated leak report.
  /// If not provided, the [Links.gitHubTroubleshooting] is used.
  static String get troubleshootingDocumentationLink => documentationLinkToUse;
  static set troubleshootingDocumentationLink(String value) =>
      documentationLinkToUse = value;

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

      _leakTracker = LeakTracker(config, _phase);

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
      return true;
    }());
  }

  /// Dispatches an object event to the leak_tracker.
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

  /// Dispatches object creation to the leak_tracker.
  ///
  /// Use [context] to provide additional information,
  /// that may help in leak troubleshooting.
  /// The value must be serializable.
  ///
  /// Noop if object creation is already dispatched.
  static void dispatchObjectCreated({
    required String library,
    required String className,
    required Object object,
    Map<String, dynamic>? context,
  }) {
    assert(() {
      _baseliner?.takeSample();
      if (phase.ignoredLeaks.isIgnored(className)) return true;
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

  /// Dispatches object disposal to the leak_tracker.
  ///
  /// See [dispatchObjectCreated] for parameters documentation.
  ///
  /// Noop if object disposal is already dispatched.
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

  /// Dispatches additional context information to the leak_tracker.
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
      result = _leakTracker?.objectTracker.checkNotGCed();
      return true;
    }());

    await (result ?? Future<void>.value());
  }

  /// Declares all not disposed objects as leaks.
  ///
  /// Should be invoked after test execution, to detect
  /// not disposed objects, even if they are not GCed yet.
  static void declareNotDisposedObjectsAsLeaks() {
    _leakTracker?.objectTracker.declareAllNotDisposedAsLeaks();
  }

  /// Performs an operation for each object, not detected as GCed.
  static Iterable tracked() =>
      _leakTracker?.objectTracker.tracked() ?? const Iterable.empty();
}
