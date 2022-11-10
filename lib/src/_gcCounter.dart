// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Detects if objects are expected to be disposed by watchung GC cycles.
class GcCounter {
  /// Number of full GC cycles since start of the isolate.
  int get gcCount =>
      // TODO(polina-c): replace with reachabilityBarrier from 'dart:developer'
      // when https://dart-review.git.corp.google.com/c/sdk/+/266424 reaches
      // Flutter master.
      DateTime.now().millisecondsSinceEpoch;

  /// True, if the disposed object is expected to be GCed,
  /// assuming at the disposal moment it was referenced only
  /// by the the disposal invoker.
  bool shouldBeGced(int gcCountAtDisposal, DateTime timeAtDisposal) =>
      shouldObjectBeGced(
        gcCountAtDisposal: gcCountAtDisposal,
        timeAtDisposal: timeAtDisposal,
        currentGcCount: gcCount,
        currentTime: DateTime.now(),
      );
}

/// The default is pessimistic assuming that user will want to
/// detect leaks not more often than a second.
@visibleForTesting
const defaultDisposalTimeBuffer = Duration(milliseconds: 100);

@visibleForTesting
const gcCountBuffer = 2;

/// [disposalBuffer] is time to allow the disposal invoker
/// to release the reference to the object.
@visibleForTesting
bool shouldObjectBeGced({
  required int gcCountAtDisposal,
  required DateTime timeAtDisposal,
  required int currentGcCount,
  required DateTime currentTime,
  Duration? disposalBuffer,
}) =>
    currentGcCount - gcCountAtDisposal >= gcCountBuffer &&
    currentTime.difference(timeAtDisposal) >=
        (disposalBuffer ?? defaultDisposalTimeBuffer);
