// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Values in [FieldNames] and [EventType] should be identical to ones used in
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

typedef StartTrackingCallback = void Function({
  required Object object,
  required Map<String, dynamic>? context,
  required String library,
  required String className,
});

typedef DispatchDisposalCallback = void Function({
  required Object object,
  required Map<String, dynamic>? context,
});

void dispatchObjectEvent(
  Map<Object, Map<String, Object>> event, {
  required StartTrackingCallback onStartTracking,
  required DispatchDisposalCallback onDispatchDisposal,
}) {
  assert(event.length == 1);
  final entry = event.entries.first;

  final object = entry.key;
  final fields = entry.value;

  final eventType = fields[_FieldNames.eventType] as String;

  final libraryName = fields[_FieldNames.libraryName]?.toString() ?? '';
  final className = fields[_FieldNames.className]?.toString() ?? '';

  if (eventType == _EventType.created) {
    onStartTracking(
      object: object,
      context: null,
      library: libraryName,
      className: className,
    );
  } else if (eventType == _EventType.disposed) {
    onDispatchDisposal(object: object, context: null);
  } else {
    throw StateError('Unexpected event type for $object: $eventType.');
  }
}
