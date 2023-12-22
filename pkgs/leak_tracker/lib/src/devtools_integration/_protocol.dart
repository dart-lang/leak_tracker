// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../shared/shared_model.dart';
import 'messages.dart';

/// Generic parameter is not used for encoder, because
/// the message type cannot be detected in runtime.
typedef AppMessageEncoder = Map<String, dynamic> Function(dynamic message);

typedef AppMessageDecoder<T> = T Function(Map<String, dynamic> message);

enum Channel {
  requestToApp,
  eventFromApp,
  responseFromApp,
}

/// Codes to identify event types in interaction between
/// an application and DevTools.
///
/// When application starts real tracking, it sends [started]. As soon as it
/// catch new leaks, it sends [summary] information about collected leaks.
///
/// When user wants to get more info about the collected leaks, they
/// request details in DevTools, DevTools sends [detailsRequest] to the app,
/// and the app responds with [leakDetails].
@visibleForTesting
enum Codes {
  // Events from app.
  started,
  summary,

  // Requests to app.
  detailsRequest,

  // Successful responses from app.
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

/// Deserialize [message] into an object with the specified [T] type.
T openEnvelope<T>(
  Map<String, dynamic> message,
  Channel channel,
) {
  final envelope =
      _envelopeByCode<T>(message[_JsonFields.envelopeCode] as String);
  assert(envelope.channel == channel);
  return envelope.decode(message[_JsonFields.content] as Map<String, Object?>);
}

/// Information necessary to serialize and deserialize an instance of type [T],
/// so that the message type can be auto-detected.
class _Envelope<T> {
  const _Envelope(this.code, this.channel, this.decode, this.encode);

  /// Serialization code, that corresponds to [T].
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

  _Envelope<LeakTrackingStarted>(
    Codes.started,
    Channel.eventFromApp,
    LeakTrackingStarted.fromJson,
    (message) => (message as LeakTrackingStarted).toJson(),
  ),
  _Envelope<LeakSummary>(
    Codes.summary,
    Channel.eventFromApp,
    LeakSummary.fromJson,
    (message) => (message as LeakSummary).toJson(),
  ),

  // Requests to app.

  _Envelope<RequestForLeakDetails>(
    Codes.detailsRequest,
    Channel.requestToApp,
    (Map<String, dynamic> json) => RequestForLeakDetails(),
    (message) => {},
  ),

  // Responses from app.

  _Envelope<Leaks>(
    Codes.leakDetails,
    Channel.responseFromApp,
    Leaks.fromJson,
    (message) => (message as Leaks).toJson(),
  ),

  _Envelope<LeakTrackingTurnedOffError>(
    Codes.leakTrackingTurnedOffError,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => LeakTrackingTurnedOffError(),
    (message) => {},
  ),

  _Envelope<UnexpectedRequestTypeError>(
    Codes.unexpectedRequestTypeError,
    Channel.responseFromApp,
    UnexpectedRequestTypeError.fromJson,
    (message) => (message as UnexpectedRequestTypeError).toJson(),
  ),

  _Envelope<UnexpectedError>(
    Codes.unexpectedError,
    Channel.responseFromApp,
    UnexpectedError.fromJson,
    (message) => (message as UnexpectedError).toJson(),
  ),
];

_Envelope<T> _envelopeByCode<T>(String codeString) {
  return _envelopesByCode[codeString]! as _Envelope<T>;
}

// ignore: library_private_types_in_public_api, public for testing
_Envelope envelopeByType(Type type) => _envelopesByType[type]!;

final _envelopesByCode = {for (var e in envelopes) e.code.name: e};

final _envelopesByType = {for (var e in envelopes) e.type: e};
