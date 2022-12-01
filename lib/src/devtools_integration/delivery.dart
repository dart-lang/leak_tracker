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
  final theEnvelope = envelope<T>();
  assert(theEnvelope.channel == Channel.requestFromApp);
  postEvent(memoryLeakTrackingExtensionName, {
    _JsonFields.envelopeCode: theEnvelope.code,
    _JsonFields.content: theEnvelope.encode(message),
  });
}

/// Parses request from application to DevTools.
///
/// Ignores events from other extensions and event types that do not have right [withHistory].
T? parseRequestFromApp<T>(Event event) {
  if (event.extensionKind != memoryLeakTrackingExtensionName) return null;

  final data = event.json!['extensionData'] as Map<String, dynamic>;
  final envelope = envelopeByCode(data[_JsonFields.envelopeCode] as String);

  assert(envelope.channel == Channel.requestFromApp);
  return envelope.parse(data[_JsonFields.content]);
}
