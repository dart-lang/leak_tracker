// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../leak_tracker.dart';
import '_dispatcher.dart' as dispatcher;
import '_object_tracker.dart';

ObjectTracker? _objectTracker;

/// Enables leak tracking for the application.
///
/// See usage guidance at https://github.com/dart-lang/leak_tracker.
void enableLeakTracking({LeakTrackingConfiguration? config}) {
  config ??= LeakTrackingConfiguration();
  if (_objectTracker != null)
    throw StateError('Leak tracking is alredy enabled.');
  _objectTracker = ObjectTracker(
    classesToCollectStackTraceOnStart: config.classesToCollectStackTraceOnStart,
    classesToCollectStackTraceOnDisposal:
        config.classesToCollectStackTraceOnDisposal,
  );
}

/// Disables leak tracking for the application.
///
/// See usage guidance at https://github.com/dart-lang/leak_tracker.
void disableLeakTracking() {
  _objectTracker = null;
}

/// Dispatches an object event to the leak tracker.
///
/// Consumes the MemoryAllocations event format:
/// https://github.com/flutter/flutter/blob/a479718b02a818fb4ac8d4900bf08ca389cd8e7d/packages/flutter/lib/src/foundation/memory_allocations.dart#L51
void dispatchObjectEvent(Map<Object, Map<String, Object>> event) {
  final tracker = _objectTracker;
  if (tracker == null)
    throw StateError('Leak tracking should be enabled to dispatch event.');
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
}) =>
    throw UnimplementedError();

/// Dispatches object disposal to the leak tracker.
///
/// See [dispatchObjectCreated] for parameters documentation.
void dispatchObjectDisposed({
  required Object object,
  Map<String, dynamic>? context,
}) =>
    throw UnimplementedError();

/// Dispatches additional context information to the leak tracker.
///
/// See [dispatchObjectCreated] for parameters documentation.
void dispatchObjectTrace({
  required Object object,
  Map<String, dynamic>? context,
}) =>
    throw UnimplementedError();
