// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../leak_tracker.dart';
import '_dispatcher.dart' as dispatcher;
import '_leak_checker.dart';
import '_object_tracker.dart';
import '_primitives.dart';
import 'devtools_integration/_registration.dart';
import 'devtools_integration/messages.dart';
import 'model.dart';

final _objectTracker = ObjectRef<ObjectTracker?>(null);
LeakChecker? _leakChecker;

/// Enables leak tracking for the application.
///
/// See usage guidance at https://github.com/dart-lang/leak_tracker.
void enableLeakTracking({LeakTrackingConfiguration? config}) {
  config ??= LeakTrackingConfiguration();
  if (_objectTracker.value != null)
    throw StateError('Leak tracking is alredy enabled.');

  final newTracker = ObjectTracker(
    classesToCollectStackTraceOnStart: config.classesToCollectStackTraceOnStart,
    classesToCollectStackTraceOnDisposal:
        config.classesToCollectStackTraceOnDisposal,
  );

  _objectTracker.value = newTracker;

  _leakChecker = LeakChecker(
    leakProvider: newTracker,
    checkPeriod: config.checkPeriod,
    leakListener: config.leakListener,
    stdoutSink: config.stdoutLeaks ? StdoutSummarySink() : null,
    devToolsSink: config.notifyDevTools ? DevToolsSummarySink() : null,
  );

  if (config.notifyDevTools) {
    setupDevToolsIntegration(_objectTracker);
  } else {
    registerLeakTrackingServiceExtention();
  }
}

/// Disables leak tracking for the application.
///
/// See usage guidance at https://github.com/dart-lang/leak_tracker.
void disableLeakTracking() {
  _leakChecker?.dispose();
  _leakChecker = null;
  _objectTracker.value?.dispose();
  _objectTracker.value = null;
}

ObjectTracker _tracker() {
  // TODO(polina-c): return both tracker and checker when tuples get released.
  final result = _objectTracker.value;
  assert((result == null) == (_leakChecker == null));
  if (result == null) throw StateError('Leak tracking should be enabled.');
  return result;
}

/// Dispatches an object event to the leak tracker.
///
/// Consumes the MemoryAllocations event format:
/// https://github.com/flutter/flutter/blob/a479718b02a818fb4ac8d4900bf08ca389cd8e7d/packages/flutter/lib/src/foundation/memory_allocations.dart#L51
void dispatchObjectEvent(Map<Object, Map<String, Object>> event) {
  final tracker = _tracker();
  dispatcher.dispatchObjectEvent(event, tracker);
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
  final tracker = _tracker();
  tracker.startTracking(
    object,
    context: context,
    trackedClass: fullClassName(library: library, shortClassName: className),
  );
}

/// Dispatches object disposal to the leak tracker.
///
/// See [dispatchObjectCreated] for parameters documentation.
void dispatchObjectDisposed({
  required Object object,
  Map<String, dynamic>? context,
}) {
  final tracker = _tracker();
  tracker.dispatchDisposal(object, context: context);
}

/// Dispatches additional context information to the leak tracker.
///
/// See [dispatchObjectCreated] for parameters documentation.
void dispatchObjectTrace({
  required Object object,
  Map<String, dynamic>? context,
}) {
  final tracker = _tracker();
  tracker.addContext(object, context: context);
}

/// Checks for leaks and outputs [LeakSummary] as configured.
void checkLeaks() {
  // TODO(polina-c): get checker as result when tuples are released.
  _tracker();
  _leakChecker!.checkLeaks();
}

/// Returns details of the leaks collected since last invocation.
///
/// The same object may be reported as leaked twice: first
/// as non GCed, and then as GCed late.
Leaks collectLeaks() {
  final tracker = _tracker();
  return tracker.collectLeaks();
}
