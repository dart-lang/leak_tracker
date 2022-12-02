// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'model.dart';

/// Generic parameter is not used for encoder, because the message type cannot be detected in runtime.
typedef AppMessageEncoder = Map<String, dynamic> Function(dynamic message);
typedef AppMessageDecoder<T> = T Function(Map<String, dynamic> message);

enum Codes {
  started,
  summary,
  detailsRequest,
  details,
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
}

/// Envelopes should be unique by message type.
@visibleForTesting
final envelopes = [
  Envelope<LeakTrackingStarted>(
    Codes.started,
    Channel.requestFromApp,
    (Map<String, dynamic> json) => LeakTrackingStarted.fromJson(json),
    (message) => (message as LeakTrackingStarted).toJson(),
  ),
  Envelope<LeakSummary>(
    Codes.summary,
    Channel.requestFromApp,
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
    Codes.details,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => Leaks.fromJson(json),
    (message) => (message as Leaks).toJson(),
  ),
];

Envelope<T> envelopeByCode<T>(String codeString) {
  final code = Codes.byName(codeString);
  return _envelopesByCode[code]! as Envelope<T>;
}

Envelope envelopeByType(Type type) => _envelopesByType[type]!;

late final _envelopesByCode = Map<String, Envelope>.fromIterable(
  envelopes,
  key: (e) => e.code,
  value: (e) => e,
);

late final _envelopesByType = Map<Type, Envelope>.fromIterable(
  envelopes,
  key: (e) => e.type,
  value: (e) => e,
);
