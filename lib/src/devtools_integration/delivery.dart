// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import '_envelopes.dart';
import 'primitives.dart';

/// Names for json fields.
class _JsonFields {
  static const String content = 'content';
}

class RequestToApp<T extends Object> {
  RequestToApp(this.message);

  RequestToApp.fromRequestParameters(Map<String, String> parameters)
      : message = Envelope.open(
          jsonDecode(parameters[_JsonFields.content]!),
          Channel.requestToApp,
        ) as T;

  Map<String, String> toRequestParameters() {
    return {
      _JsonFields.content:
          jsonEncode(Envelope.seal(message, Channel.requestToApp)),
    };
  }

  final T message;
}

class ResponseFromApp<T extends Object> {
  ResponseFromApp(this.message);

  ResponseFromApp.fromServiceResponse(Response response)
      : message = Envelope.open(response.json!, Channel.responseFromApp) as T;

  final T message;

  ServiceExtensionResponse toServiceResponse() {
    return ServiceExtensionResponse.result(
      jsonEncode(Envelope.seal(message, Channel.responseFromApp)),
    );
  }
}

class EventFromApp<T extends Object> {
  EventFromApp(this.message);

  static EventFromApp? fromVmServiceEvent(Event event) {
    if (event.extensionKind != memoryLeakTrackingExtensionName) return null;
    final data = event.json!['extensionData'] as Map<String, dynamic>;
    return EventFromApp(Envelope.open(data, Channel.eventFromApp));
  }

  final T message;

  void post() {
    postEvent(
      memoryLeakTrackingExtensionName,
      Envelope.seal(message, Channel.eventFromApp),
    );
  }
}
