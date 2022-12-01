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

typedef _MessageParser<T> = T Function(String value);
typedef _MessageEncoder<T> = String Function(T value);

enum Codes {
  started,
  summary,
}

class _Envelope<T> {
  _Envelope(this.code, this.channel, this.parser, this.encoder);

  final Codes code;
  final Channel channel;
  final _MessageParser<T> parser;
  final _MessageEncoder<T> encoder;

  Type get messageType => T;
}

/// Envelopes should be unique by message type.
final _envelopes = [
  _Envelope<LeakTrackingStarted>(
    Codes.started,
    Channel.requestFromApp,
    (String protocolVersion) => LeakTrackingStarted(protocolVersion),
    (LeakTrackingStarted started) => started.protocolVersion,
  ),
  _Envelope<LeakSummary>(
    Codes.summary,
    Channel.requestFromApp,
    (String json) => LeakSummary.fromJson(jsonDecode(json)),
    (LeakSummary summary) => jsonEncode(summary.toJson()),
  ),
];

late final _factoriesByCode = Map<String, _Envelope>.fromIterable(
  _envelopes,
  key: (e) => e.code,
  value: (e) => e,
);

late final _factoriesByType = Map<Type, _Envelope>.fromIterable(
  _envelopes,
  key: (e) => e.type,
  value: (e) => e,
);

T parseMessage<T>(String code, String value) =>
    _factoriesByCode[code]!.parser(value) as T;

class LeakTrackingStarted {
  LeakTrackingStarted(this.protocolVersion);

  final String protocolVersion;
}
