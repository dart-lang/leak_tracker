// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

/// Name of extension to integrate the leak tracker with DevDools.
const String memoryLeakTrackingExtensionName = 'ext.dart.memoryLeakTracking';

class _EventFields {
  static const String eventType = 'type';
  static const String error = 'error';
}

/// Types of events that can be sent from DevTools to the connected application,
/// if [memoryLeakTrackingExtensionName] is registered.
class _IncomingEventTypes {
  static const String requestForLeakDetails = 'requestForLeakDetails';
}

class OutgoingEventKinds {
  static const String memoryLeaksSummary = 'memoryLeaksSummary';
}

abstract class LeakTrackingEvent {}

class RequestForLeakDetails extends LeakTrackingEvent {}

LeakTrackingEvent parseEvent(Map<String, String> parameters) {
  final eventType = parameters[_EventFields.eventType];

  if (eventType == _IncomingEventTypes.requestForLeakDetails)
    return RequestForLeakDetails();

  throw ArgumentError('Unexpected event type: $eventType.');
}

ServiceExtensionResponse errorResponse(String error) {
  return ServiceExtensionResponse.result(
    jsonEncode({_EventFields.error, error}),
  );
}

late final successResponse = ServiceExtensionResponse.result(jsonEncode({}));
