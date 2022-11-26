// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'model.dart';

enum _FromAppEventTypes {
  leakTrackingStarted,
  memoryLeakSummary,
  //memoryLeakDetails,
}

abstract class FromAppEvent {}

void sendLeakTrackingStarted() {
  postEvent(
    _FromAppEventTypes.leakTrackingStarted.name,
    {},
  );
}

void sendLeakSummary(LeakSummary summary) {
  postEvent(
    _FromAppEventTypes.memoryLeakSummary.name,
    summary.toJson(),
  );
}
