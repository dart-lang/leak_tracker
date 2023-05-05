// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '_snapshot.dart';
import 'model.dart';

Timer? timer;
final _takenSnapshots = <SnapshotInfo>[];
late UageTrackingConfig _config;
bool _snapshottingIsInProgress = false;

/// Enables auto-snapshotting, based on the value of [ProcessInfo.currentRss] (dart:io).
///
/// If auto-snapshotting is already enabled, resets it.
/// See [AutoSnapshottingConfig] for details.
/// Use [stopAutoSnapshotOnMemoryOveruse] to stop auto-snapshotting.
/// Snapshotting operation may cause a delay in the main thread.
void trackUsage(UageTrackingConfig config) {
  stopAutoSnapshotOnMemoryOveruse();
  final directory = config.autoSnapshottingConfig?.directory;
  if (directory != null) {
    _createDirectoryIfNotExists(directory);
  }
  _config = config;
  timer = Timer.periodic(config.interval, (_) {
    if (_snapshottingIsInProgress) return;
    _snapshottingIsInProgress = true;
    unawaited(
      _maybeTakeSnapshot().then((_) => _snapshottingIsInProgress = false),
    );
  });
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

Future<void> _maybeTakeSnapshot() async {
  final config = _config.autoSnapshottingConfig;
  if (config == null) return;
  final rss = ProcessInfo.currentRss;
  if (rss < config.thresholdMb.mbToBytes()) {
    return;
  }

  // Directory size validation is heavier than rss check, so we do it after.
  // We do not stop monitoring, in case user will free some space.
  if (_isDirectoryOversized(config)) return;

  final stepMb = config.increaseMb;

  if (_takenSnapshots.isEmpty) {
    _takeSnapshot(config, rss: rss);
    if (stepMb == null) stopAutoSnapshotOnMemoryOveruse();
    return;
  }

  assert(_takenSnapshots.isNotEmpty);

  if (stepMb == null) {
    throw StateError(
      'Autosnapshotting should be off if step is null and there is a snapshot already taken',
    );
  }

  final nextAllowedSnapshotTime =
      _takenSnapshots.last.timestamp.add(config.minDelayBetweenSnapshots);
  if (nextAllowedSnapshotTime.isAfter(DateTime.now())) {
    return;
  }

  final nextThreshold = _takenSnapshots.last.rss + stepMb.mbToBytes();
  if (rss >= nextThreshold) {
    _takeSnapshot(config, rss: rss);
  }
}

void _takeSnapshot(AutoSnapshottingConfig config, {required int rss}) {
  final snapshotNumber = _takenSnapshots.length + 1;

  final record = saveSnapshot(
    config.directory,
    rss: rss,
    snapshotNumber: snapshotNumber,
  );
  _takenSnapshots.add(record);
  config.onSnapshot?.call(record);
}

/// Disables auto-snapshotting if it is enabled by [trackUsage].
void stopAutoSnapshotOnMemoryOveruse() {
  timer?.cancel();
  timer = null;
  _takenSnapshots.clear();
}
