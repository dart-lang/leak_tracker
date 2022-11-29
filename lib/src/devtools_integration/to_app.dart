// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'model.dart';

abstract class ToAppEvent {
  Map<String, dynamic> toJson();
}

/// Types of events that can be sent from DevTools to the connected application,
/// if [memoryLeakTrackingExtensionName] is registered.
enum _EventTypes {
  requestForLeakDetails('requestForLeakDetails'),
  ;

  const _EventTypes(this.value);

  final String value;
}

enum _EventFields {
  eventType('type'),
  ;

  const _EventFields(this.value);

  final String value;
}

class RequestForLeakDetails extends ToAppEvent {
  RequestForLeakDetails();

  factory RequestForLeakDetails.fromJson(Map<String, dynamic> json) =>
      RequestForLeakDetails();

  @override
  Map<String, dynamic> toJson() => {
        _EventFields.eventType.value: _EventTypes.requestForLeakDetails.value,
      };
}

ToAppEvent parseToAppEvent(Map<String, String> parameters) {
  final eventType = parameters[_EventFields.eventType.value];

  if (eventType == _EventTypes.requestForLeakDetails.value)
    return RequestForLeakDetails();

  throw ArgumentError('Unexpected event type: $eventType.');
}
