// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A record of a taken snapshot.
class SnapshotRecord {
  SnapshotRecord(
    this.fileName, {
    required this.snapshotNumber,
    required this.rss,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String fileName;
  final int snapshotNumber;
  final int rss;
  final DateTime timestamp;
}

/// A callback that is called when a snapshot is taken.
typedef SnapshotCallback = void Function(SnapshotRecord record);

/// Configures auto-snapshotting, based on the value of ProcessInfo.currentRss (dart:io).
///
/// The snapshots will be taken as soon as the value becomes more than [thresholdMb],
/// and saved to the [folder]. The snapshots will be re-taken when the value
/// increases more than by [stepMb], till hitting the [folderSizeLimitMb].
/// The [folder] will be created if it does not exist.
///
/// Set [interval] to customize how often to verify memory consumption.
///
/// If [stepMb] is null, only one snapshot will be taken.
///
/// The folder size will be chaecked before saving snapshot, so the folder
/// may become bigger than [folderSizeLimitMb].
///
/// The [onSnapshot] callback is called when a snapshot is taken.
///
/// Set [minDelayBetweenSnapshots] to make sure snapshots do not trigger each other.
class AutoSnapshottingConfig {
  const AutoSnapshottingConfig({
    this.thresholdMb = 1024, // 1Gb
    this.stepMb = 512, // 0.5Gb
    this.folder = '~/Downloads/dart_momory_snapshots',
    this.folderSizeLimitMb = 10000, // 10Gb
    this.interval = const Duration(minutes: 1),
    this.minDelayBetweenSnapshots = const Duration(minutes: 5),
    this.onSnapshot,
  });

  final int thresholdMb;
  final int? stepMb;
  final String folder;
  final int folderSizeLimitMb;
  final Duration interval;
  final Duration minDelayBetweenSnapshots;
  final SnapshotCallback? onSnapshot;
}
