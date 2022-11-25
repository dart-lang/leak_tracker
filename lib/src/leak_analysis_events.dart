// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

/// Name of extension to integrate the leak tracker with DevDools.
const String memoryLeakTrackingExtensionName = 'ext.dart.memoryLeakTracking';

class _EventFields {
  static const String eventType = 'type';
}

/// Types of events that can be sent from DevTools to the connected application,
/// if [memoryLeakTrackingExtensionName] is registered.
class _IncomingEventTypes {
  static const String requestForLeakDetails = 'requestForLeakDetails';
}

class OutgoingEventKinds {
  static const String memoryLeakSummary = 'memoryLeakSummary';
  static const String memoryLeakDetails = 'memoryLeakDetails';
}

abstract class LeakTrackingEvent {}

class RequestForLeakDetails extends LeakTrackingEvent {}

LeakTrackingEvent parseEvent(Map<String, String> parameters) {
  final eventType = parameters[_EventFields.eventType];

  if (eventType == _IncomingEventTypes.requestForLeakDetails)
    return RequestForLeakDetails();

  throw ArgumentError('Unexpected event type: $eventType.');
}

enum ResponseErrors {
  unexpectedError(0),
  unexpectedEventType(1);

  const ResponseErrors(this.code);

  final int code;
}

ServiceExtensionResponse errorResponse(ResponseErrors error, String details) {
  return ServiceExtensionResponse.error(error.code, details);
}

late final successResponse = ServiceExtensionResponse.result(jsonEncode({}));
