// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:meta/meta.dart';

/// Wrapper for reachabilityBarrier, for mocking purposes.
class GcCounter {
  /// Number of full GC cycles since start of the isolate.
  int get gcCount => reachabilityBarrier;
}

/// Delta of GC time, enough for a non reachable object to be GCed.
///
/// Theoretically, 2 should be enough, however it gives false positives
/// if there is no activity in the application for ~5 minutes.
@visibleForTesting
const gcCountBuffer = 3;

/// True, if the disposed object is expected to be GCed,
/// assuming at the disposal moment it was referenced only
/// by the the disposal invoker.
bool shouldObjectBeGced({
  required int gcCountAtDisposal,
  required DateTime timeAtDisposal,
  required int currentGcCount,
  required DateTime currentTime,
  required Duration disposalTimeBuffer,
}) =>
    currentGcCount - gcCountAtDisposal >= gcCountBuffer &&
    currentTime.difference(timeAtDisposal) >= disposalTimeBuffer;
