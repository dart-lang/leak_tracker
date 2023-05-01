// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

/// A record of a taken snapshot.
class SnapshotInfo {
  SnapshotInfo(
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
typedef SnapshotCallback = void Function(SnapshotInfo record);

/// Configures auto-snapshotting, based on the value of [ProcessInfo.currentRss] (dart:io).
///
/// Automatic snapshots will begin to be taken when the rss value exceeds [thresholdMb].
/// The snapshots will be saved to [directory].
///
/// The snapshots will be re-taken when the value
/// increases more than by [stepMb], until the size of [directory] exceeds
/// [directorySizeLimitMb].
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
    this.directory = 'dart_memory_snapshots',
    this.directorySizeLimitMb = 10240, // 10Gb
    this.interval = const Duration(seconds: 1),
    this.minDelayBetweenSnapshots = const Duration(seconds: 10),
    this.onSnapshot,
  });

  /// The rss value in Mb that will trigger the first snapshot.
  final int thresholdMb;

  /// The value by which the rss value should increase to take another snapshot.
  ///
  /// If [stepMb] is null, only one snapshot will be taken.
  final int? stepMb;

  /// The directory where snapshots will be saved.
  ///
  /// If the directory does not exist, it will be created.
  ///
  /// If the path is relative, it will be relative to the current working directory.
  final String directory;

  /// The size limit for the [directory] in Mb.
  ///
  /// The directory size will be checked before a snapshot is taken and saved,
  /// so the directory may exceed the size specified by [directorySizeLimitMb]
  /// depending on the size of the snapshot.
  final int directorySizeLimitMb;

  /// How often to verify memory consumption.
  final Duration interval;

  /// How long to wait after taking a snapshot before taking another one.
  final Duration minDelayBetweenSnapshots;

  /// A callback that is called when a snapshot is taken.
  final SnapshotCallback? onSnapshot;

  /// The absolute path to the [directory].
  String get directoryAbsolute => path.absolute(directory);

  @override
  String toString() {
    final formatter = NumberFormat('#,###,000');
    return 'thresholdMb: ${formatter.format(thresholdMb)}\n'
        'stepMb: ${stepMb == null ? 'null' : formatter.format(stepMb)}\n'
        'directorySizeLimitMb: ${formatter.format(directorySizeLimitMb)}\n'
        'directory: $directory\n'
        'directoryAbsolute: $directoryAbsolute\n'
        'interval: $interval\n'
        'minDelayBetweenSnapshots: $minDelayBetweenSnapshots\n';
  }
}
