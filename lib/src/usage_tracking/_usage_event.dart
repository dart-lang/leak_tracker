// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../shared/_util.dart';
import 'model.dart';

class UsageEventCreator {
  UsageEventCreator(this.config);

  final UsageEventsConfig config;

  late MemoryUsageEvent _previousEvent;

  void createFirstUsageEvent() => _triggerEvent(
        MemoryUsageEvent(
          delta: null,
          previousEventTime: null,
          rss: ProcessInfo.currentRss,
        ),
      );

  void mayBeCreateUsageEvent() {
    final rss = ProcessInfo.currentRss;
    final delta = (rss - _previousEvent.rss).abs();

    if (delta < config.deltaMb.mbToBytes()) return;

    _triggerEvent(
      MemoryUsageEvent(
        delta: delta,
        previousEventTime: _previousEvent.timestamp,
        rss: ProcessInfo.currentRss,
      ),
    );
  }

  void _triggerEvent(MemoryUsageEvent event) {
    _previousEvent = event;
    config.onUsageEvent(event);
  }
}
