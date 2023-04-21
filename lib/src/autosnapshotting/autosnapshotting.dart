// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enables auto-snapshotting, based on the value of ProcessInfo.currentRss (dart:io).
///
/// The snapshots will be taken as soon as the value becomes more than [thresholdMb],
/// and saved to the [folder]. The snapshots will be re-taken when the value
/// increases more than by [stepMb], till hitting the [folderSizeLimitMb].
/// The [folder] will be created if it does not exist.
///
/// To disable snapshotting, invoke [stopAutoSnapshotOnMemoryOveruse].
void autoSnapshotOnMemoryOveruse({
  required int thresholdMb,
  required int? stepMb,
  required String folder,
  required int folderSizeLimitMb,
}) {}

/// Disables auto-snapshotting if it is enabled.
void stopAutoSnapshotOnMemoryOveruse() {}
