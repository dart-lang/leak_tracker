// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'model.dart';

bool _snapshottingIsInProgress = false;
final _takenSnapshots = <SnapshotInfo>[];
bool _noSnapshotsAnyMore = false;

/// Saves a memory heap snapshot of the current process, to the [directory].
///
/// Returns the name of the file where the snapshot was saved.
///
/// The file name contains process id, snapshot number and current RSS.
SnapshotInfo saveSnapshot(
  String directory, {
  required int rss,
  required int snapshotNumber,
  void Function(String fileName) snapshotter =
      NativeRuntime.writeHeapSnapshotToFile,
}) {
  final fileName = path.absolute(
    path.join(directory, 'snapshot-$pid-$snapshotNumber-rss$rss.json'),
  );

  snapshotter(fileName);

  return SnapshotInfo(fileName, snapshotNumber: snapshotNumber, rss: rss);
}

Future<void> maybeTakeSnapshot() async {
  if (_noSnapshotsAnyMore) return;

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
    if (stepMb == null) _noSnapshotsAnyMore = true;
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
