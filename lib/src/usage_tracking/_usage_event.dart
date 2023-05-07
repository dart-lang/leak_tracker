// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../shared/_util.dart';
import 'model.dart';

class UsageEventCreator {
  UsageEventCreator(this.config);

  final UsageEventsConfig config;

  late UsageInfo _previousInfo;

  void createFirstUsageEvent() => _triggerEvent(
        UsageInfo(
          delta: null,
          previousEventTime: null,
          rss: ProcessInfo.currentRss,
        ),
      );

  void mayBeCreateUsageEvent() {
    final rss = ProcessInfo.currentRss;
    final delta = (rss - _previousInfo.rss).abs();

    if (delta < config.deltaMb.mbToBytes()) return;

    _triggerEvent(
      UsageInfo(
        delta: delta,
        previousEventTime: _previousInfo.timestamp,
        rss: ProcessInfo.currentRss,
      ),
    );
  }

  void _triggerEvent(UsageInfo info) {
    _previousInfo = info;
    config.onUsageEvent(info);
  }
}
