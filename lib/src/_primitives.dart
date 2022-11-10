// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Time to allow the disposal invoker
/// to release the reference to the object.
const Duration _disposalBuffer = Duration(microseconds: 100);

/// Wrapper for [reachabilityBarrier], for mocking purposes.
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
  bool shouldBeGced(int disposalGcCount, DateTime disposalTime) =>
      gcCount - disposalGcCount >= 2 &&
      DateTime.now().difference(disposalTime) > _disposalBuffer;
}
