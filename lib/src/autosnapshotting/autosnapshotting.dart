// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '_snapshot.dart';
import 'model.dart';

Timer? _theTimer;
final _takenSnapshots = <SnapshotRecord>[];
late AutoSnapshottingConfig _config;
bool _snapshottingIsInProgress = false;

/// Enables auto-snapshotting, based on the value of ProcessInfo.currentRss (dart:io).
///
/// If autosnapshotting is already enabled, resets it.
/// See [AutoSnapshottingConfig] for details.
/// Use [stopAutoSnapshotOnMemoryOveruse] to stop auto-snapshotting.
/// Snapshotting operation may cause a delay in the main thread.
void autoSnapshotOnMemoryOveruse({
  AutoSnapshottingConfig config = const AutoSnapshottingConfig(),
}) {
  stopAutoSnapshotOnMemoryOveruse();
  _createFolderIfNotExists(config.folder);
  _config = config;
  _theTimer = Timer.periodic(config.interval, (_) {
    if (_snapshottingIsInProgress) return;
    _snapshottingIsInProgress = true;
    _maybeTakeSnapshot();
    _snapshottingIsInProgress = false;
  });
}

void _createFolderIfNotExists(String folder) {
  final dir = Directory(folder);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}

extension _SizeConversion on int {
  int mbToBites() => this * 1024 * 1024;
}

bool _isFolderOversized() {
  final folderSize = Directory(_config.folder)
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.lengthSync())
      .fold<int>(0, (a, b) => a + b);
  return folderSize >= _config.folderSizeLimitMb.mbToBites();
}

void _maybeTakeSnapshot() {
  final rss = ProcessInfo.currentRss;
  if (rss < _config.thresholdMb.mbToBites()) {
    return;
  }

  // Folder size validation is havier than rss check, so we do it after.
  // We do not stop monitoring, in case user will free some space.
  if (_isFolderOversized()) return;

  final stepMb = _config.stepMb;

  if (_takenSnapshots.isEmpty) {
    _takeSnapshot(rss: rss);
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
      _takenSnapshots.last.timestamp.add(_config.minDelayBetweenSnapshots);
  if (nextAllowedSnapshotTime.isAfter(DateTime.now())) {
    return;
  }

  final nextThreshold = _takenSnapshots.last.rss + stepMb.mbToBites();
  if (rss >= nextThreshold) {
    _takeSnapshot(rss: rss);
  }
}

void _takeSnapshot({required int rss}) {
  final snapshotNumber = _takenSnapshots.length + 1;

  final record = saveSnapshot(
    _config.folder,
    rss: rss,
    snapshotNumber: snapshotNumber,
  );
  _takenSnapshots.add(record);
  _config.onSnapshot?.call(record);
}

/// Disables auto-snapshotting if it is enabled by [autoSnapshotOnMemoryOveruse].
void stopAutoSnapshotOnMemoryOveruse() {
  _theTimer?.cancel();
  _theTimer = null;
  _takenSnapshots.clear();
}
