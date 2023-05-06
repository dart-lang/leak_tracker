// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '_snapshot.dart';
import 'model.dart';

Timer? timer;

late UageTrackingConfig _config;

/// Enables memory usage tracking, based on the value of [ProcessInfo.currentRss] (dart:io).
///
/// If tracking is already enabled, resets it.
/// See [UageTrackingConfig] for details.
/// Use [stopMemoryUsageTracking] to stop auto-snapshotting.
/// Snapshotting operation may cause a delay in the main thread.
void trackMemoryUsage(UageTrackingConfig config) {
  stopMemoryUsageTracking();
  _config = config;
  if (config.isNoOp) return;

  final directory = config.autoSnapshottingConfig?.directory;
  if (directory != null) {
    _createDirectoryIfNotExists(directory);
  }

  _triggerFirstUsageEvent();
  timer = Timer.periodic(config.interval, (_) {
    if (_snapshottingIsInProgress) return;

    _snapshottingIsInProgress = true;
    unawaited(
      _maybeTakeSnapshot().then((_) => _snapshottingIsInProgress = false),
    );

    _maybeTriggerUsageEvent();
  });
}

void _maybeTriggerUsageEvent() {
  final handler = _config.onUsageEvent;
  if (handler == null) return;
}

void _triggerFirstUsageEvent() {
  final rss = ProcessInfo.currentRss;
  _config.onUsageEvent?.call(
    UsageInfo(delta: null, period: null, rss: rss),
  );
  _previousRss = rss;
  _previousRssTimestamp = DateTime.now();
}

/// Stops memory usage tracking if it is started by [trackMemoryUsage].
void stopMemoryUsageTracking() {
  timer?.cancel();
  timer = null;
  _takenSnapshots.clear();
}

void _createDirectoryIfNotExists(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}

extension _SizeConversion on int {
  int mbToBytes() => this * 1024 * 1024;
}

bool _isDirectoryOversized(AutoSnapshottingConfig config) {
  final directorySize = Directory(config.directory)
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.lengthSync())
      .fold<int>(0, (a, b) => a + b);
  return directorySize >= config.directorySizeLimitMb.mbToBytes();
}
