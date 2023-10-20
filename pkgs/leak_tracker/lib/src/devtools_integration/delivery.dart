// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import '../shared/_formatting.dart';
import '_protocol.dart';
import 'primitives.dart';

/// Names for json fields.
class _JsonFields {
  static const String content = 'content';
}

class RequestToApp<T extends Object> {
  RequestToApp(this.message);

  RequestToApp.fromRequestParameters(Map<String, String> parameters)
      : message = openEnvelope<T>(
          jsonDecode(parameters[_JsonFields.content]!) as Map<String, Object?>,
          Channel.requestToApp,
        );

  Map<String, String> toRequestParameters() {
    return {
      _JsonFields.content:
          jsonEncode(sealEnvelope(message, Channel.requestToApp)),
    };
  }

  final T message;
}

class ResponseFromApp<T extends Object> {
  ResponseFromApp(this.message);

  ResponseFromApp.fromJson(Map<String, dynamic> json)
      : this(openEnvelope<T>(json, Channel.responseFromApp));

  ResponseFromApp.fromServiceResponse(Response response)
      : this.fromJson(response.json!);

  final T message;

  ServiceExtensionResponse toServiceResponse() =>
      ServiceExtensionResponse.result(
        jsonEncode(toJson(), toEncodable: contextToString),
      );

  Map<String, dynamic> toJson() =>
      sealEnvelope(message, Channel.responseFromApp);
}

class EventFromApp<T extends Object> {
  EventFromApp(this.message);

  EventFromApp.fromJson(Map<String, dynamic> json)
      : this(openEnvelope<T>(json, Channel.eventFromApp));

  static EventFromApp? fromVmServiceEvent(Event event) {
    if (event.extensionKind != memoryLeakTrackingExtensionName) return null;
    final data = event.json!['extensionData'] as Map<String, dynamic>;
    return EventFromApp.fromJson(data);
  }

  final T message;

  Map<String, dynamic> messageAsJson() =>
      sealEnvelope(message, Channel.eventFromApp);

  void post() {
    postEvent(
      memoryLeakTrackingExtensionName,
      messageAsJson(),
    );
  }
}
