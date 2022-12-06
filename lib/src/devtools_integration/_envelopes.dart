// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../model.dart';
import 'messages.dart';

/// Generic parameter is not used for encoder, because the message type cannot be detected in runtime.
typedef AppMessageEncoder = Map<String, dynamic> Function(dynamic message);

typedef AppMessageDecoder<T> = T Function(Map<String, dynamic> message);

enum Channel {
  requestToApp,
  eventFromApp,
  responseFromApp,
}

enum Codes {
  // Events from app.
  started,
  summary,

  // Requests to app.
  detailsRequest,

  // Successfull responses from app.
  leakDetails,

  // Error responses from app.
  leakTrackingTurnedOffError,
  unexpectedError,
  unexpectedRequestTypeError,
  ;

  static Codes byName(String name) =>
      Codes.values.where((e) => e.name == name).single;
}

class _JsonFields {
  static const envelopeCode = 'code';
  static const content = 'content';
}

/// Serializes an object so that it's type can be reconstructed.
Map<String, dynamic> sealEnvelope(Object message, Channel channel) {
  final theEnvelope = envelopeByType(message.runtimeType);
  assert(theEnvelope.channel == channel);
  return {
    _JsonFields.envelopeCode: theEnvelope.code.name,
    _JsonFields.content: theEnvelope.encode(message),
  };
}

/// Deserialize [message] into an opbejct of a right type.
Object openEnvelope(
  Map<String, dynamic> message,
  Channel channel,
) {
  final envelope = envelopeByCode(message[_JsonFields.envelopeCode] as String);
  assert(envelope.channel == channel);
  return envelope.decode(message[_JsonFields.content]);
}

/// Information necessary to serialize and deserialize an instance of type [T],
/// so that type can be auto-detected.
class Envelope<T> {
  const Envelope(this.code, this.channel, this.decode, this.encode);

  /// Serialization code, that corresponts to [T].
  final Codes code;

  /// Communication channel, that should be used for messages of type [T].
  final Channel channel;

  /// Decoder for the message.
  final AppMessageDecoder<T> decode;

  /// Encoder for the message.
  final AppMessageEncoder encode;

  Type get type => T;
}

/// Envelopes should be unique by message type.
@visibleForTesting
final envelopes = [
  // Events from app.

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

  // Requests to app.

  Envelope<RequestForLeakDetails>(
    Codes.detailsRequest,
    Channel.requestToApp,
    (Map<String, dynamic> json) => RequestForLeakDetails(),
    (message) => {},
  ),

  // Responses from app.

  Envelope<Leaks>(
    Codes.leakDetails,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => Leaks.fromJson(json),
    (message) => (message as Leaks).toJson(),
  ),

  Envelope<LeakTrackingTurnedOffError>(
    Codes.leakTrackingTurnedOffError,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => LeakTrackingTurnedOffError(),
    (message) => {},
  ),

  Envelope<UnexpectedRequestTypeError>(
    Codes.unexpectedRequestTypeError,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => UnexpectedRequestTypeError.fromJson(json),
    (message) => (message as UnexpectedRequestTypeError).toJson(),
  ),

  Envelope<UnexpectedError>(
    Codes.unexpectedError,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => UnexpectedError.fromJson(json),
    (message) => (message as UnexpectedError).toJson(),
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
