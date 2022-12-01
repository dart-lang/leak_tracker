// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'model.dart';

enum Channel {
  requestToApp,
  requestFromApp,
  responseFromApp,
}

typedef MessageParser<T> = T Function(Map<String, dynamic> value);
typedef MessageEncoder<T> = Map<String, dynamic> Function(T value);

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
  Envelope(this.code, this.channel, this.parse, this.encode);

  final Codes code;
  final Channel channel;
  final MessageParser<T> parse;
  final MessageEncoder<T> encode;

  Type get type => T;
}

/// Envelopes should be unique by message type.
final _envelopes = [
  Envelope<LeakTrackingStarted>(
    Codes.started,
    Channel.requestFromApp,
    (Map<String, dynamic> json) => LeakTrackingStarted.fromJson(json),
    (LeakTrackingStarted started) => started.toJson(),
  ),
  Envelope<LeakSummary>(
    Codes.summary,
    Channel.requestFromApp,
    (Map<String, dynamic> json) => LeakSummary.fromJson(json),
    (LeakSummary message) => message.toJson(),
  ),
  Envelope<RequestForDetails>(
    Codes.detailsRequest,
    Channel.requestToApp,
    (Map<String, dynamic> json) => RequestForDetails(),
    (RequestForDetails message) => {},
  ),
  Envelope<Leaks>(
    Codes.details,
    Channel.responseFromApp,
    (Map<String, dynamic> json) => Leaks.fromJson(json),
    (Leaks message) => message.toJson(),
  ),
];

Envelope envelopeByCode(String codeString) {
  final code = Codes.byName(codeString);
  return _envelopesByCode[code]!;
}

Envelope<T> envelope<T>() {
  return _envelopesByType[T]! as Envelope<T>;
}

late final _envelopesByCode = Map<String, Envelope>.fromIterable(
  _envelopes,
  key: (e) => e.code,
  value: (e) => e,
);

late final _envelopesByType = Map<Type, Envelope>.fromIterable(
  _envelopes,
  key: (e) => e.type,
  value: (e) => e,
);
