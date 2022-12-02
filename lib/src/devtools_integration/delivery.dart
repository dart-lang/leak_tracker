// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import '_envelopes.dart';
import 'model.dart';

void postFromAppEvent(Object message) {
  postEvent(
    memoryLeakTrackingExtensionName,
    sealEnvelope(message, Channel.requestFromApp),
  );
}

/// Parses request from application to DevTools.
///
/// Ignores events from other extensions and event types that do not have right [withHistory].
Object? parseRequestFromApp(Event event) {
  if (event.extensionKind != memoryLeakTrackingExtensionName) return null;
  final data = event.json!['extensionData'] as Map<String, dynamic>;
  return openEnvelope(data, Channel.requestFromApp);
}

/// Parses response for a request sent from DevTools to app.
T parseResponseFromApp<T>(Response response) {
  final envelope = envelopeByType(T);
  return envelope.decode(response.json ?? {});
}

Map<String, dynamic> encodeMessage(Object message, Channel channel) {
  final envelope = envelopeByType(message.runtimeType);
  assert(envelope.channel == channel);
  return envelope.encode(message);
}
