// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';

import 'model.dart';

abstract class AppMessage {
  String get eventType;
  Map<String, dynamic> toJson();
}

typedef MessageParser<T extends AppMessage> = T Function(
  Map<String, dynamic> json,
);

enum Channel {
  eventToApp,
  eventFromApp,
  responseFromApp,
}

class MessageFactory<T extends AppMessage> {
  MessageFactory(this.code, this.channel, this.parser);

  final String code;
  final Channel channel;
  final MessageParser<T> parser;
}

final factories =

/// Codes are hard coded instead of using `toString`,
/// because they are part of protocol and should not change
/// when class is renamed.
enum MessageTypes {
  leakTrackingStarted(
    'started',
    Channel.eventFromApp,
    LeakTrackingStarted,
  ),
  memoryLeakSummary(
    'summary',
    Channel.eventFromApp,
    LeakTrackingSummary,
  ),
  ;

  const MessageTypes(this.code, this.channel, this.type, this.parser);

  static MessageTypes? byCode(String value) =>
      MessageTypes.values.firstWhereOrNull((element) => element.code == value);

  final String code;
  final Type type;
  final Channel channel;
  final MessageParser parser;
}

enum _EventFields {
  protocolVersion('version'),
  leakSummary('summary'),
  time('time'),
  ;

  const _EventFields(this.value);

  final String value;
}

class LeakTrackingStarted extends AppMessage {
  LeakTrackingStarted(this.protocolVersion);

  factory LeakTrackingStarted.fromJson(Map<String, dynamic> json) {
    final protocolVersion =
        _cast<String>(json[_EventFields.protocolVersion.value]);
    return LeakTrackingStarted(protocolVersion);
  }

  @override
  Map<String, dynamic> toJson() => {
        _EventFields.eventType.value:
            FromAppEventTypes.leakTrackingStarted.value,
        _EventFields.protocolVersion.value: appLeakTrackerProtocolVersion,
      };

  final String protocolVersion;

  @override
  final channel = Channel.eventFromApp;
}

class LeakTrackingSummary extends AppMessage {
  LeakTrackingSummary(this.leakSummary, {DateTime? time}) {
    this.time = time ?? DateTime.now();
  }

  factory LeakTrackingSummary.fromJson(Map<String, dynamic> json) {
    final summary = LeakSummary.fromJson(
      _cast<Map<String, dynamic>>(json[_EventFields.leakSummary.value]),
    );
    final time = DateTime.fromMillisecondsSinceEpoch(
      _cast<int>(json[_EventFields.time.value]),
    );

    return LeakTrackingSummary(summary, time: time);
  }

  @override
  Map<String, dynamic> toJson() => {
        _EventFields.eventType.value: FromAppEventTypes.memoryLeakSummary.value,
        _EventFields.leakSummary.value: leakSummary,
        _EventFields.time.value: time.millisecondsSinceEpoch,
      };

  final LeakSummary leakSummary;
  late DateTime time;

  @override
  final channel = Channel.eventFromApp;
}

/// This function is needed, because `as` does not provide callstack when fails.
T _cast<T>(value) {
  if (value is T) return value;
  throw ArgumentError(
    '$value is of type ${value.runtimeType} that is not subtype of $T',
  );
}
