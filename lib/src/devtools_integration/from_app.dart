// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'model.dart';

abstract class FromAppEvent {}

enum _FromAppEventTypes {
  leakTrackingStarted,
  memoryLeakSummary,
  memoryLeakDetails,
}

enum _EventFields {
  protocolVersion('version');

  const _EventFields(this.value);

  final String value;
}

void sendLeakTrackingStarted() {
  postEvent(
    _FromAppEventTypes.leakTrackingStarted.name,
    {_EventFields.protocolVersion.value: protocolVersion},
  );
}

void sendLeakSummary(LeakSummary summary) {
  postEvent(
    _FromAppEventTypes.memoryLeakSummary.name,
    summary.toJson(),
  );
}

void sendLeakDetails(Leaks leaks) {
  postEvent(
    _FromAppEventTypes.memoryLeakDetails.name,
    leaks.toJson(),
  );
}
