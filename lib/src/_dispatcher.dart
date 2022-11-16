// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_object_tracker.dart';

// Values in [FieldNames] and [EventType] should be identical to ones osed in
// https://github.com/flutter/flutter/blob/a479718b02a818fb4ac8d4900bf08ca389cd8e7d/packages/flutter/lib/src/foundation/memory_allocations.dart#L23

class _FieldNames {
  static const String eventType = 'eventType';
  static const String libraryName = 'libraryName';
  static const String className = 'className';
}

class _EventType {
  static const String created = 'created';
  static const String disposed = 'disposed';
}

void dispatch(
  Map<Object, Map<String, Object>> event,
  ObjectTracker tracker,
) {
  assert(event.length == 1);
  final entry = event.entries.first;

  final object = entry.key;
  final fields = entry.value;

  final type = fields[_FieldNames.eventType] as String;

  if (type == _EventType.created) {
    tracker.startTracking(object, context: {});
  } else if (type == _EventType.disposed) {
    tracker.registerDisposal(object, context: null);
  } else {
    throw StateError('Unexpected event type for $object: $type.');
  }
}
