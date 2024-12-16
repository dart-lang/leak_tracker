// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/_primitives.dart';
import '_leak_reporter.dart';
import '_object_tracker.dart';
import 'primitives/model.dart';

class LeakTracker {
  LeakTracker(LeakTrackingConfig config, ObjectRef<PhaseSettings> phase) {
    objectTracker = ObjectTracker(
      disposalTime: config.disposalTime,
      numberOfGcCycles: config.numberOfGcCycles,
      maxRequestsForRetainingPath: config.maxRequestsForRetainingPath,
    );

    leakReporter = LeakReporter(
      leakProvider: objectTracker,
      checkPeriod: config.checkPeriod,
      onLeaks: config.onLeaks,
      stdoutSink: config.stdoutLeaks ? StdoutSummarySink() : null,
    );
  }

  late final ObjectTracker objectTracker;

  late final LeakReporter leakReporter;

  void dispose() {
    objectTracker.dispose();
    leakReporter.dispose();
  }
}
