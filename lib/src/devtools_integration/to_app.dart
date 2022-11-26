// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'model.dart';

/// Types of events that can be sent from DevTools to the connected application,
/// if [memoryLeakTrackingExtensionName] is registered.
enum ToAppEventTypes {
  requestForLeakDetails,
}

abstract class ToAppEvent {}

class _EventFields {
  static const String eventType = 'type';
}

class RequestForLeakDetails extends ToAppEvent {}

ToAppEvent parseToAppEvent(Map<String, String> parameters) {
  final eventType = parameters[_EventFields.eventType];

  if (eventType == ToAppEventTypes.requestForLeakDetails.name)
    return RequestForLeakDetails();

  throw ArgumentError('Unexpected event type: $eventType.');
}
