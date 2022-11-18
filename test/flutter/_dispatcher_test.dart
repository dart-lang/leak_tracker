// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/src/_dispatcher.dart';
import 'package:leak_tracker/src/_object_tracker.dart';
import 'package:leak_tracker/src/leak_tracker_model.dart';

void main() {
  test('dispatchObjectEvent dispatches Flutter SDK instrumentation.', () {
    final tracker = _MockObjectTracker();
    MemoryAllocations.instance
        .addListener((event) => dispatchObjectEvent(event.toMap(), tracker));

    final picture = _createPicture();

    expect(tracker.events, hasLength(1));
    final event = tracker.events[0];
    expect(event.type, _EventType.started);
    expect(event.object, picture);
    expect(event.context, null);
    expect(event.trackedClass, 'dart:ui/Picture');
  });
}

Picture _createPicture() {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}

enum _EventType {
  started,
  disposed,
}

class _Event {
  _Event(this.type, this.object, this.context, this.trackedClass);

  final _EventType type;
  final Object object;
  final Map<String, dynamic>? context;
  final String? trackedClass;
}

class _MockObjectTracker extends ObjectTracker {
  _MockObjectTracker() : super(LeakTrackingConfiguration());

  final events = <_Event>[];

  @override
  void startTracking(
    Object object, {
    required Map<String, dynamic>? context,
    required String trackedClass,
  }) =>
      events.add(_Event(_EventType.started, object, context, trackedClass));

  @override
  void dispatchDisposal(
    Object object, {
    required Map<String, dynamic>? context,
  }) =>
      events.add(_Event(_EventType.disposed, object, context, null));
}
