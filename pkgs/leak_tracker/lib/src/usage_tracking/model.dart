// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

/// A record of a taken snapshot.
class SnapshotEvent {
  SnapshotEvent(
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
typedef SnapshotCallback = void Function(SnapshotEvent event);

/// A record of a memory usage event.
class MemoryUsageEvent {
  MemoryUsageEvent({
    required this.delta,
    required DateTime? previousEventTime,
    required this.rss,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now() {
    if (previousEventTime == null) {
      period = null;
    } else {
      period = this.timestamp.difference(previousEventTime);
    }
  }

  /// Difference with previouse rss value.
  ///
  /// Equals to [null] for first event.
  final int? delta;

  /// Time since previous event.
  ///
  /// Equals to [null] for first event.
  late Duration? period;

  /// RSS memory usage.
  final int rss;

  ///
  final DateTime timestamp;
}

/// A callback that is called for memory usage event.
typedef UsageCallback = void Function(MemoryUsageEvent event);

/// Configures memory usage tracking.
///
/// Set [interval] to customize how often to verify memory usage.
class UsageTrackingConfig {
  const UsageTrackingConfig({
    this.usageEventsConfig,
    this.autoSnapshottingConfig,
    this.interval = const Duration(seconds: 1),
  });

  /// Configuration for snapshotting.
  final AutoSnapshottingConfig? autoSnapshottingConfig;

  /// Configuration for usage events.
  final UsageEventsConfig? usageEventsConfig;

  /// How often to verify memory usage.
  final Duration interval;

  bool get isNoOp =>
      autoSnapshottingConfig == null && usageEventsConfig == null;

  @override
  String toString() {
    return 'interval: $interval\n'
        '$usageEventsConfig\n'
        '$autoSnapshottingConfig';
  }
}

/// Configures memory usage tracking.
///
/// [onUsageEvent] will be triggered when rss value changes
/// more then by [deltaMb] since previous [onUsageEvent].
/// First [onUsageEvent] will be triggered immediately.
class UsageEventsConfig {
  const UsageEventsConfig(
    this.onUsageEvent, {
    this.deltaMb = 128,
  });

  /// A callback that is called when a snapshot is taken.
  final UsageCallback onUsageEvent;

  /// Change in memory usage to trigger [onUsageEvent].
  final int deltaMb;

  @override
  String toString() {
    final formatter = NumberFormat('#,###,000');
    return 'usageEvent.deltaMb: ${formatter.format(deltaMb)}';
  }
}

/// Configures auto-snapshotting, based on the value of `ProcessInfo.currentRss` (dart:io).
///
/// Automatic snapshots will begin to be taken when the rss value exceeds [thresholdMb].
/// The snapshots will be saved to [directory].
///
/// The snapshots will be re-taken when the value
/// increases more than by [increaseMb] since previous snapshot,
/// until the size of [directory] exceeds
/// [directorySizeLimitMb].
///
/// The [onSnapshot] callback is called when a snapshot is taken.
///
/// Set [minDelayBetweenSnapshots] to make sure snapshots do not trigger each other.
class AutoSnapshottingConfig {
  AutoSnapshottingConfig({
    this.thresholdMb = 1024, // 1Gb
    this.increaseMb = 512, // 0.5Gb
    this.directory = 'dart_memory_snapshots',
    this.directorySizeLimitMb = 10240, // 10Gb
    this.minDelayBetweenSnapshots = const Duration(seconds: 10),
    this.onSnapshot,
  }) {
    if (minDelayBetweenSnapshots <= Duration.zero) {
      throw ArgumentError.value(
        minDelayBetweenSnapshots,
        'minDelayBetweenSnapshots',
        'must be positive',
      );
    }
  }

  /// The rss value in Mb that will trigger the first snapshot.
  final int thresholdMb;

  /// The value by which the rss value should increase, since
  /// previous snapshot, to take another snapshot.
  ///
  /// If [increaseMb] is null, only one snapshot will be taken.
  final int? increaseMb;

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
        'autosnapshot.increaseMb: ${increaseMb == null ? 'null' : formatter.format(increaseMb)}\n'
        'directorySizeLimitMb: ${formatter.format(directorySizeLimitMb)}\n'
        'directory: $directory\n'
        'directoryAbsolute: $directoryAbsolute\n'
        'minDelayBetweenSnapshots: $minDelayBetweenSnapshots';
  }
}
