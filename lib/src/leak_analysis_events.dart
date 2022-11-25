// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Name of extension to integrate the leak tracker with DevDools.
const String memoryLeakTrackingExtensionName = 'ext.dart.memoryLeakTracking';

class _EventFields {
  static const String eventType = 'eventType';
}

/// Types of events that can be sent from DevTools to the connected application,
/// if [memoryLeakTrackingExtensionName] is registered.
class _EventTypes {
  static const String requestForLeakDetails = 'requestForLeakDetails';
}

abstract class LeakTrackingEvent {}

class RequestForLeakDetails extends LeakTrackingEvent {}

LeakTrackingEvent parseEvent(Map<String, String> parameters) {
  final eventType = parameters[_EventFields.eventType];

  if (eventType == _EventTypes.requestForLeakDetails)
    return RequestForLeakDetails();

  throw ArgumentError('Unexpected event type: $eventType.');
}
