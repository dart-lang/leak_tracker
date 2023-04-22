// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '_snapshot.dart';
import 'model.dart';

Timer? _theTimer;
final _takenSnapshots = <SnapshotRecord>[];
late AutosnapshottingConfig _config;
bool _snapshottingIsInProgress = false;

/// Enables auto-snapshotting, based on the value of ProcessInfo.currentRss (dart:io).
///
/// If autosnapshotting is already enabled, resets it.
/// See [AutosnapshottingConfig] for details.
/// Use [stopAutoSnapshotOnMemoryOveruse] to stop auto-snapshotting.
/// Snapshot operation can cause a delay in the main thread.
void autoSnapshotOnMemoryOveruse(AutosnapshottingConfig config) {
  stopAutoSnapshotOnMemoryOveruse();
  _config = config;
  _theTimer = Timer.periodic(config.interval, (_) {
    if (_snapshottingIsInProgress) return;
    _snapshottingIsInProgress = true;
    _maybeTakeSnapshot();
    _snapshottingIsInProgress = false;
  });
}

extension _SizeConversion on int {
  int mbToBites() => this * 1024 * 1024;
}

void _stopIfFolderOversized() {
  final folderSize = Directory(_config.folder)
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.lengthSync())
      .fold<int>(0, (a, b) => a + b);
  if (folderSize >= _config.folderSizeLimitMb.mbToBites()) {
    stopAutoSnapshotOnMemoryOveruse();
  }
}

void _maybeTakeSnapshot() {
  _stopIfFolderOversized();

  final rss = ProcessInfo.currentRss;
  if (rss < _config.thresholdMb.mbToBites()) {
    return;
  }

  final stepMb = _config.stepMb;

  if (_takenSnapshots.isEmpty) {
    _takeSnapshot(rss: rss);
    if (stepMb == null) stopAutoSnapshotOnMemoryOveruse();
    return;
  }

  if (stepMb == null) {
    throw StateError(
      'Autosnapshotting should be off if step is null and there is a snapshot already taken',
    );
  }

  // TODO: process steps.
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
