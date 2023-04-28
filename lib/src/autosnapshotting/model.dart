// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

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
/// and saved to the [directory]. The snapshots will be re-taken when the value
/// increases more than by [stepMb], till hitting the [directorySizeLimitMb].
/// The [directory] will be created if it does not exist.
///
/// If [stepMb] is null, only one snapshot will be taken.
///
/// The directory size will be checked before a snapshot is taken and saved,
/// so the directory may exceed the size specified by [directorySizeLimitMb]
/// depending on the size of the snapshot.
///
/// The [onSnapshot] callback is called when a snapshot is taken.
///
/// Set [interval] to customize how often to verify memory consumption.
/// Set [minDelayBetweenSnapshots] to make sure snapshots do not trigger each other.
/// For example, if [interval] is 1 second and [minDelayBetweenSnapshots] is 5 seconds,
/// the app will check size every second, but after taking snapshot,
/// will delay for 5 seconds to allow memory to settle.
class AutoSnapshottingConfig {
  const AutoSnapshottingConfig({
    this.thresholdMb = 1024, // 1Gb
    this.stepMb = 512, // 0.5Gb
    this.directory = 'dart_momory_snapshots',
    this.directorySizeLimitMb = 10240, // 10Gb
    this.interval = const Duration(seconds: 1),
    this.minDelayBetweenSnapshots = const Duration(seconds: 10),
    this.onSnapshot,
  });

  final int thresholdMb;
  final int? stepMb;
  final String directory;
  final int directorySizeLimitMb;
  final Duration interval;
  final Duration minDelayBetweenSnapshots;
  final SnapshotCallback? onSnapshot;

  String get folderAbsolute => path.absolute(directory);

  @override
  String toString() {
    final formatter = NumberFormat('#,###,000');
    return 'thresholdMb: ${formatter.format(thresholdMb)}\n'
        'stepMb: ${stepMb == null ? 'null' : formatter.format(stepMb)}\n'
        'folderSizeLimitMb: ${formatter.format(directorySizeLimitMb)}\n'
        'folder: $directory\n'
        'folderAbsolute: $folderAbsolute\n'
        'interval: $interval\n'
        'minDelayBetweenSnapshots: $minDelayBetweenSnapshots\n';
  }
}
