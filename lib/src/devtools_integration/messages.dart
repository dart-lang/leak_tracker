// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

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
}

class Envelope<T> {
  Envelope(this.code, this.channel, this.parse, this.encode);

  final Codes code;
  final Channel channel;
  final MessageParser<T> parse;
  final MessageEncoder<T> encode;

  Type get messageType => T;
}

class _JsonFields {
  static const version = 'version';
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
    (LeakSummary summary) => summary.toJson(),
  ),
];

late final _envelopesByCode = Map<String, Envelope>.fromIterable(
  _envelopes,
  key: (e) => e.code,
  value: (e) => e,
);

late final envelopesByType = Map<Type, Envelope>.fromIterable(
  _envelopes,
  key: (e) => e.type,
  value: (e) => e,
);

class LeakTrackingStarted {
  LeakTrackingStarted(this.protocolVersion);
  factory LeakTrackingStarted.fromJson(Map<String, dynamic> json) =>
      LeakTrackingStarted(json[_JsonFields.version] as String);

  Map<String, dynamic> toJson() => {_JsonFields.version: protocolVersion};

  final String protocolVersion;
}
