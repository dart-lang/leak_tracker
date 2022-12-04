// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../_model.dart';
import 'messages.dart';
import 'primitives.dart';

/// Generic parameter is not used for encoder, because the message type cannot be detected in runtime.
typedef AppMessageEncoder = Map<String, dynamic> Function(dynamic message);

typedef AppMessageDecoder<T> = T Function(Map<String, dynamic> message);

enum Codes {
  started,
  summary,
  detailsRequest,
  leakDetails,

  successResponse,

  leakTrackingTurnedOffError,
  unexpectedError,
  unexpectedEventTypeError,
  ;

  static Codes byName(String name) =>
      Codes.values.where((e) => e.name == name).single;
}

class Envelope<T> {
  Envelope(this.code, this.channel, this.decode, this.encode);

  final Codes code;
  final Channel channel;
  final AppMessageDecoder<T> decode;
  final AppMessageEncoder encode;

  Type get type => T;

  static Map<String, dynamic> seal(Object message, Channel channel) {
    final theEnvelope = envelopeByType(message.runtimeType);
    assert(theEnvelope.channel == channel);
    return {
      _JsonFields.envelopeCode: theEnvelope.code.name,
      _JsonFields.content: theEnvelope.encode(message),
    };
  }

  static Object open(
    Map<String, dynamic> json,
    Channel channel,
  ) {
    final envelope = envelopeByCode(json[_JsonFields.envelopeCode] as String);
    assert(envelope.channel == channel);
    return envelope.decode(json[_JsonFields.content]);
  }
}

/// Envelopes should be unique by message type.
@visibleForTesting
final envelopes = [
  Envelope<LeakTrackingStarted>(
    Codes.started,
    Channel.eventFromApp,
    (Map<String, dynamic> json) => LeakTrackingStarted.fromJson(json),
    (message) => (message as LeakTrackingStarted).toJson(),
  ),
  Envelope<LeakSummary>(
    Codes.summary,
    Channel.eventFromApp,
    (Map<String, dynamic> json) => LeakSummary.fromJson(json),
    (message) => (message as LeakSummary).toJson(),
  ),
  Envelope<RequestForLeakDetails>(
    Codes.detailsRequest,
    Channel.requestToApp,
    (Map<String, dynamic> json) => RequestForLeakDetails(),
    (message) => {},
  ),
  Envelope<Leaks>(
    Codes.leakDetails,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => Leaks.fromJson(json),
    (message) => (message as Leaks).toJson(),
  ),
];

Envelope<T> envelopeByCode<T>(String codeString) {
  return _envelopesByCode[codeString]! as Envelope<T>;
}

Envelope envelopeByType(Type type) => _envelopesByType[type]!;

late final _envelopesByCode = Map<String, Envelope>.fromIterable(
  envelopes,
  key: (e) => (e as Envelope).code.name,
  value: (e) => e,
);

late final _envelopesByType = Map<Type, Envelope>.fromIterable(
  envelopes,
  key: (e) => e.type,
  value: (e) => e,
);

class _JsonFields {
  static const envelopeCode = 'code';
  static const content = 'content';
}
