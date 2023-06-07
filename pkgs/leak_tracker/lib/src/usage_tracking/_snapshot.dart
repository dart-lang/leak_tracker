// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../shared/_util.dart';
import 'model.dart';

class AutoSnapshotter {
  AutoSnapshotter(this.config);

  final AutoSnapshottingConfig config;

  bool _snapshottingIsInProgress = false;
  SnapshotEvent? _previousSnapshot;
  bool _noSnapshotsAnyMore = false;

  Future<void> autoSnapshot() async {
    if (_noSnapshotsAnyMore || _snapshottingIsInProgress) return;
    _snapshottingIsInProgress = true;
    await _maybeTakeSnapshot();
    _snapshottingIsInProgress = false;
  }

  Future<void> _maybeTakeSnapshot() async {
    final rss = ProcessInfo.currentRss;
    if (rss < config.thresholdMb.mbToBytes()) {
      return;
    }

    // Directory size validation is heavier than rss check, so we do it after.
    // We do not stop monitoring, in case user will free some space.
    if (_isDirectoryOversized()) return;

    final stepMb = config.increaseMb;

    if (_previousSnapshot == null) {
      _takeSnapshot(rss: rss);
      if (stepMb == null) _noSnapshotsAnyMore = true;
      return;
    }

    final previous = _previousSnapshot!;

    if (stepMb == null) {
      throw StateError(
        'Autosnapshotting should be off if step is null and there is a snapshot already taken',
      );
    }

    final nextAllowedSnapshotTime =
        previous.timestamp.add(config.minDelayBetweenSnapshots);
    if (nextAllowedSnapshotTime.isAfter(DateTime.now())) {
      return;
    }

    final nextThreshold = previous.rss + stepMb.mbToBytes();
    if (rss >= nextThreshold) {
      _takeSnapshot(rss: rss);
    }
  }

  void _takeSnapshot({required int rss}) {
    final snapshotNumber = (_previousSnapshot?.snapshotNumber ?? 0) + 1;

    final snapshot = saveSnapshot(
      config.directory,
      rss: rss,
      snapshotNumber: snapshotNumber,
    );
    _previousSnapshot = snapshot;
    config.onSnapshot?.call(snapshot);
  }

  bool _isDirectoryOversized() {
    final directorySize = Directory(config.directory)
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.lengthSync())
        .fold<int>(0, (a, b) => a + b);
    return directorySize >= config.directorySizeLimitMb.mbToBytes();
  }
}

/// Saves a memory heap snapshot of the current process, to the [directory].
///
/// Returns the name of the file where the snapshot was saved.
///
/// The file name contains process id, snapshot number and current RSS.
SnapshotEvent saveSnapshot(
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

  return SnapshotEvent(fileName, snapshotNumber: snapshotNumber, rss: rss);
}
