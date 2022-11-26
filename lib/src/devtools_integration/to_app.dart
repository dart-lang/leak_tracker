// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'model.dart';

abstract class ToAppEvent {}

/// Types of events that can be sent from DevTools to the connected application,
/// if [memoryLeakTrackingExtensionName] is registered.
enum _ToAppEventTypes {
  requestForLeakDetails('requestForLeakDetails');

  const _ToAppEventTypes(this.value);

  final String value;
}

class _EventFields {
  static const String eventType = 'type';
}

class RequestForLeakDetails extends ToAppEvent {}

ToAppEvent parseToAppEvent(Map<String, String> parameters) {
  final eventType = parameters[_EventFields.eventType];

  if (eventType == _ToAppEventTypes.requestForLeakDetails.value)
    return RequestForLeakDetails();

  throw ArgumentError('Unexpected event type: $eventType.');
}
