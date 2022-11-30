// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';

import 'model.dart';

enum _MessageChannel {
  eventToApp,
  eventFromApp,
  responseFromApp,
}

abstract class Message {
  _MessageChannel get channel;
  Map<String, dynamic> toJson();
}

/// Strings are hard coded instead of using `toString`,
/// because they are part of protocol and should not change
/// when class is renamed.
enum _FromAppEventTypes {
  leakTrackingStarted('leakTrackingStarted'),
  memoryLeakSummary('memoryLeakSummary'),
  ;

  const _FromAppEventTypes(this.value);

  static _FromAppEventTypes? byValue(String value) => _FromAppEventTypes.values
      .firstWhereOrNull((element) => element.value == value);

  final String value;
}

enum _EventFields {
  eventType('type'),
  protocolVersion('version'),
  leakSummary('summary'),
  time('time'),
  ;

  const _EventFields(this.value);

  final String value;
}

class LeakTrackingStarted extends Message {
  LeakTrackingStarted(this.protocolVersion);

  factory LeakTrackingStarted.fromJson(Map<String, dynamic> json) {
    final protocolVersion =
        _cast<String>(json[_EventFields.protocolVersion.value]);
    return LeakTrackingStarted(protocolVersion);
  }

  @override
  Map<String, dynamic> toJson() => {
        _EventFields.eventType.value:
            _FromAppEventTypes.leakTrackingStarted.value,
        _EventFields.protocolVersion.value: appLeakTrackerProtocolVersion,
      };

  final String protocolVersion;

  @override
  final channel = _MessageChannel.eventFromApp;
}

class LeakTrackingSummary extends Message {
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
        _EventFields.eventType.value:
            _FromAppEventTypes.memoryLeakSummary.value,
        _EventFields.leakSummary.value: leakSummary,
        _EventFields.time.value: time.millisecondsSinceEpoch,
      };

  final LeakSummary leakSummary;
  late DateTime time;

  @override
  final channel = _MessageChannel.eventFromApp;
}

void postFromAppEvent(Message message) {
  assert(message.channel == _MessageChannel.eventFromApp);
  postEvent(
    memoryLeakTrackingExtensionName,
    message.toJson(),
  );
}

/// Parses event from application to DevTools.
///
/// Ignores events from other extensions and event types that do not have right [withHistory].
Message? parseFromAppEvent(Event event) {
  if (event.extensionKind != memoryLeakTrackingExtensionName) return null;

  final data = event.json!['extensionData'] as Map<String, dynamic>;

  final typeString = data[_EventFields.eventType.value] as String;
  final type = _FromAppEventTypes.byValue(typeString);
  if (type == null) throw ArgumentError('Unexpected event type: $typeString.');

  switch (type) {
    case _FromAppEventTypes.leakTrackingStarted:
      return LeakTrackingStarted.fromJson(data);
    case _FromAppEventTypes.memoryLeakSummary:
      return LeakTrackingSummary.fromJson(data);
  }
}

/// This function is needed, because `as` does not provide callstack when fails.
T _cast<T>(value) {
  if (value is T) return value;
  throw ArgumentError(
    '$value is of type ${value.runtimeType} that is not subtype of $T',
  );
}
