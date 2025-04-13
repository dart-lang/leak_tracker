// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/src/leak_tracking/primitives/_dispatcher.dart';
import 'package:test/test.dart';

import '../test_infra/event_tracker.dart';

void main() {
  test('dispatchObjectEvent dispatches Flutter SDK instrumentation.', () {
    final tracker = EventTracker();

    FlutterMemoryAllocations.instance.addListener(
      (event) => dispatchObjectEvent(
        event.toMap(),
        onStartTracking: tracker.dispatchObjectCreated,
        onDispatchDisposal: tracker.dispatchObjectDisposed,
      ),
    );

    final picture = _createPicture();

    expect(tracker.events, hasLength(1));
    var event = tracker.events[0];
    tracker.events.clear();
    expect(event.type, EventType.started);
    expect(event.object, picture);
    expect(event.context, null);
    expect(event.className, 'Picture');
    expect(event.library, 'dart:ui');

    picture.dispose();

    expect(tracker.events, hasLength(1));
    event = tracker.events[0];
    tracker.events.clear();
    expect(event.type, EventType.disposed);
    expect(event.object, picture);
    expect(event.context, null);
  });
}

Picture _createPicture() {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
