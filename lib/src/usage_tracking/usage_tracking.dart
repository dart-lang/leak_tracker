// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '_snapshot.dart';
import '_usage_event.dart';
import 'model.dart';

Timer? timer;
AutoSnapshotter? autoSnapshotter;
UsageEventCreator? usageEventCreator;

/// Enables memory usage tracking, based on the value of [ProcessInfo.currentRss] (dart:io).
///
/// If tracking is already enabled, resets it.
/// See [UageTrackingConfig] for details.
/// Use [stopMemoryUsageTracking] to stop auto-snapshotting.
/// Snapshotting operation may cause a delay in the main thread.
void trackMemoryUsage(UageTrackingConfig config) {
  stopMemoryUsageTracking();
  if (config.isNoOp) return;

  if (config.autoSnapshottingConfig != null) {
    autoSnapshotter = AutoSnapshotter(config.autoSnapshottingConfig!);
  }

  if (config.usageEventsConfig != null) {
    usageEventCreator = UsageEventCreator(config.usageEventsConfig!);
    usageEventCreator!.createFirstUsageEvent();
  }

  timer = Timer.periodic(config.interval, (_) async {
    usageEventCreator?.mayBeCreateUsageEvent();
    await autoSnapshotter?.autoSnapshot();
  });
}

/// Stops memory usage tracking if it is started by [trackMemoryUsage].
void stopMemoryUsageTracking() {
  timer?.cancel();
  timer = null;

  autoSnapshotter = null;
  usageEventCreator = null;
}
