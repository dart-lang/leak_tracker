// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum EventType {
  started,
  disposed,
}

class Event {
  Event(this.type, this.object, this.context, this.library, this.className);

  final EventType type;
  final Object object;
  final Map<String, dynamic>? context;
  final String? library;
  final String? className;
}

class EventTracker {
  EventTracker();

  final events = <Event>[];

  void dispatchObjectCreated({
    required String library,
    required String className,
    required Object object,
    Map<String, dynamic>? context,
  }) {
    events.add(Event(EventType.started, object, context, library, className));
  }

  void dispatchObjectDisposed({
    required Object object,
    Map<String, dynamic>? context,
  }) {
    events.add(Event(EventType.disposed, object, context, null, null));
  }
}
