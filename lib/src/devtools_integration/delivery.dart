// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import '_envelopes.dart';
import 'model.dart';

class _JsonFields {
  static const envelopeCode = 'code';
  static const content = 'content';
}

void postFromAppEvent<T>(T message) {
  final theEnvelope = envelopeByType(T);
  assert(theEnvelope.channel == Channel.requestFromApp);
  postEvent(memoryLeakTrackingExtensionName, {
    _JsonFields.envelopeCode: theEnvelope.code,
    _JsonFields.content: theEnvelope.encode(message),
  });
}

/// Parses request from application to DevTools.
///
/// Ignores events from other extensions and event types that do not have right [withHistory].
Object? parseRequestFromApp(Event event) {
  if (event.extensionKind != memoryLeakTrackingExtensionName) return null;

  final data = event.json!['extensionData'] as Map<String, dynamic>;
  final envelope = envelopeByCode(data[_JsonFields.envelopeCode] as String);

  assert(envelope.channel == Channel.requestFromApp);
  return envelope.parse(data[_JsonFields.content]);
}

Object parseRequestToApp(Map<String, dynamic> json) {
  final envelope = envelopeByCode(json[_JsonFields.envelopeCode] as String);
  assert(envelope.channel == Channel.requestToApp);
  return envelope.parse(json[_JsonFields.content]);
}

/// Parses response for a request sent from DevTools to app.
T? parseResponseFromApp<T>(Response response) {
  final envelope = envelopeByType(T);
  return envelope.parse(response.json ?? {});
}

Map<String, dynamic> encodeMessage(Object message, Channel channel) {
  final envelope = envelopeByType(message.runtimeType);
  assert(envelope.channel == channel);
  return envelope.encode(message);
}
