// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/_object_tracker.dart';
import 'package:leak_tracker/src/leak_tracker_model.dart';

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
  MockObjectTracker() : super(LeakTrackingConfiguration());

  final events = <Event>[];

  @override
  void startTracking(
    Object object, {
    required Map<String, dynamic>? context,
    required String trackedClass,
  }) =>
      events.add(Event(EventType.started, object, context, trackedClass));

  @override
  void dispatchDisposal(
    Object object, {
    required Map<String, dynamic>? context,
  }) =>
      events.add(Event(EventType.disposed, object, context, null));
}
