// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'model.dart';

abstract class FromAppEvent {}

enum _FromAppEventTypes {
  leakTrackingStarted('leakTrackingStarted'),
  memoryLeakSummary('memoryLeakSummary'),
  memoryLeakDetails('memoryLeakDetails');

  const _FromAppEventTypes(this.value);

  final String value;
}

enum _EventFields {
  protocolVersion('version');

  const _EventFields(this.value);

  final String value;
}

class LeakTrackingStarted extends FromAppEvent {
  LeakTrackingStarted(this.protocolVersion);

  final String protocolVersion;
}

void sendLeakTrackingStarted() {
  postEvent(
    _FromAppEventTypes.leakTrackingStarted.value,
    {_EventFields.protocolVersion.value: leakTrackerProtocolVersion},
  );
}

void sendLeakSummary(LeakSummary summary) {
  postEvent(
    _FromAppEventTypes.memoryLeakSummary.value,
    summary.toJson(),
  );
}

void sendLeakDetails(Leaks leaks) {
  postEvent(
    _FromAppEventTypes.memoryLeakDetails.value,
    leaks.toJson(),
  );
}

FromAppEvent parseFromAppEvent(Event event) {
  final data = event.json!['extensionData']!;

  if (event.extensionKind == _FromAppEventTypes.leakTrackingStarted.value) {
    final version = data[_EventFields.protocolVersion.value];
    return LeakTrackingStarted(version);
  }

  throw ArgumentError('Unexpected event type: ${event.extensionKind}.');
}
