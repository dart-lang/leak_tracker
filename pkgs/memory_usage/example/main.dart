// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:memory_usage/memory_usage.dart';

void main(List<String> arguments) {
  final config = UsageTrackingConfig(
    autoSnapshottingConfig: AutoSnapshottingConfig(
      onSnapshot: (SnapshotEvent event) {},
      thresholdMb: 400,
      increaseMb: 100,
      directorySizeLimitMb: 500,
      directory: 'snapshots',
      minDelayBetweenSnapshots: const Duration(seconds: 5),
    ),
    usageEventsConfig: UsageEventsConfig(
      (MemoryUsageEvent event) {},
      deltaMb: 100,
    ),
  );

  trackMemoryUsage(config);
}
