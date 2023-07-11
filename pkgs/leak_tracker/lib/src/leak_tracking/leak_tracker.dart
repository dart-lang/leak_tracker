// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../devtools_integration/_registration.dart';
import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_dispatcher.dart' as dispatcher;
import '_leak_checker.dart';
import '_object_tracker.dart';
import 'leak_tracker_model.dart';

final _objectTracker = ObjectRef<ObjectTracker?>(null);
LeakChecker? _leakChecker;

ObjectTracker _theObjectTracker() {
  // TODO(polina-c): return both tracker and checker when tuples get released.
  final result = _objectTracker.value;
  assert((result == null) == (_leakChecker == null));
  if (result == null) throw StateError('Leak tracking should be enabled.');
  return result;
}

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
    if (_objectTracker.value != null) {
      if (!resetIfAlreadyEnabled) {
        throw StateError('Leak tracking is already enabled.');
      }
      disableLeakTracking();
    }

    final newTracker = ObjectTracker(
      leakDiagnosticConfig: theConfig.leakDiagnosticConfig,
      disposalTimeBuffer: theConfig.disposalTimeBuffer,
    );

    _objectTracker.value = newTracker;

    _leakChecker = LeakChecker(
      leakProvider: newTracker,
      checkPeriod: theConfig.checkPeriod,
      onLeaks: theConfig.onLeaks,
      stdoutSink: theConfig.stdoutLeaks ? StdoutSummarySink() : null,
      devToolsSink: theConfig.notifyDevTools ? DevToolsSummarySink() : null,
    );

    if (theConfig.notifyDevTools) {
      setupDevToolsIntegration(_objectTracker);
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
    _leakChecker?.dispose();
    _leakChecker = null;
    _objectTracker.value?.dispose();
    _objectTracker.value = null;

    return true;
  }());
}

/// Dispatches an object event to the leak tracker.
///
/// Consumes the MemoryAllocations event format:
/// https://github.com/flutter/flutter/blob/a479718b02a818fb4ac8d4900bf08ca389cd8e7d/packages/flutter/lib/src/foundation/memory_allocations.dart#L51
void dispatchObjectEvent(Map<Object, Map<String, Object>> event) {
  assert(() {
    dispatcher.dispatchObjectEvent(event, _objectTracker.value);

    return true;
  }());
}

/// Dispatches object creation to the leak tracker.
///
/// Use [context] to provide additional information, that may help in leek troubleshooting.
/// The value must be serializable.
void dispatchObjectCreated({
  required String library,
  required String className,
  required Object object,
  Map<String, dynamic>? context,
}) {
  assert(() {
    final tracker = _objectTracker.value;
    if (tracker == null) return true;

    tracker.startTracking(
      object,
      context: context,
      trackedClass: fullClassName(library: library, shortClassName: className),
    );

    return true;
  }());
}

/// Dispatches object disposal to the leak tracker.
///
/// See [dispatchObjectCreated] for parameters documentation.
void dispatchObjectDisposed({
  required Object object,
  Map<String, dynamic>? context,
}) {
  assert(() {
    final tracker = _objectTracker.value;
    if (tracker == null) return true;

    tracker.dispatchDisposal(object, context: context);
    return true;
  }());
}

/// Dispatches additional context information to the leak tracker.
///
/// See [dispatchObjectCreated] for parameters documentation.
void dispatchObjectTrace({
  required Object object,
  Map<String, dynamic>? context,
}) {
  assert(() {
    _theObjectTracker().addContext(object, context: context);
    return true;
  }());
}

/// Checks for leaks and outputs [LeakSummary] as configured.
Future<LeakSummary> checkLeaks() async {
  Future<LeakSummary>? result;

  assert(() {
    // TODO(polina-c): get checker as result when tuples are released.
    _theObjectTracker();
    result = _leakChecker!.checkLeaks();

    return true;
  }());

  return await (result ?? Future.value(LeakSummary({})));
}

/// Returns details of the leaks collected since last invocation.
///
/// The same object may be reported as leaked twice: first
/// as non GCed, and then as GCed late.
Future<Leaks> collectLeaks() async {
  Future<Leaks>? result;

  assert(() {
    result = _theObjectTracker().collectLeaks();
    return true;
  }());

  return await (result ?? Future.value(Leaks({})));
}

/// Checks for new not GCed leaks.
///
/// Invoke this method to detect the leaks earlier, when
/// the leaked objects are not GCed yet,
/// to obtain retaining path.
Future<void> checkNonGCed() async {
  Future<void>? result;

  assert(() {
    result = _theObjectTracker().checkNonGCed();
    return true;
  }());

  await (result ?? Future.value());
}
