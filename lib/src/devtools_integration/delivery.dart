// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';

import 'messages.dart';
import 'model.dart';

const _eventTypeField = 'type';
const _eventContentField = 'content';


void postFromAppEvent(AppMessage message) {
  assert(message.channel == Channel.eventFromApp);
  postEvent(
    memoryLeakTrackingExtensionName,
    {_eventTypeField: }
    message.toJson(),
  );
}

/// Parses event from application to DevTools.
///
/// Ignores events from other extensions and event types that do not have right [withHistory].
Message? parseFromAppEvent(Event event) {
  if (event.extensionKind != memoryLeakTrackingExtensionName) return null;

  final data = event.json!['extensionData'] as Map<String, dynamic>;

  final typeString = data[_EventFields.eventType.value] as String;
  final type = _FromAppEventTypes.byValue(typeString);
  if (type == null) throw ArgumentError('Unexpected event type: $typeString.');

  switch (type) {
    case _FromAppEventTypes.leakTrackingStarted:
      return LeakTrackingStarted.fromJson(data);
    case _FromAppEventTypes.memoryLeakSummary:
      return LeakTrackingSummary.fromJson(data);
  }
}
