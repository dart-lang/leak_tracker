// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_object_tracker.dart';

enum EventType {
  started,
  disposed,
}

class Event {
  Event(this.type, this.object, this.context, this.trackedClass);

  final EventType type;
  final Object object;
  final Map<String, dynamic>? context;
  final String? trackedClass;
}

class MockObjectTracker extends ObjectTracker {
  MockObjectTracker()
      : super(
          disposalTime: const Duration(milliseconds: 100),
          numberOfGcCycles: defaultNumberOfGcCycles,
          maxRequestsForRetainingPath: 0,
        );

  final events = <Event>[];

  @override
  void startTracking(
    Object object, {
    required Map<String, dynamic>? context,
    required String trackedClass,
    required PhaseSettings phase,
  }) =>
      events.add(Event(EventType.started, object, context, trackedClass));

  @override
  void dispatchDisposal(
    Object object, {
    required Map<String, dynamic>? context,
  }) =>
      events.add(Event(EventType.disposed, object, context, null));
}
