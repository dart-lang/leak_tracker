// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

/// Enables auto-snapshotting, based on the value of ProcessInfo.currentRss (dart:io).
///
/// If autosnapshotting is already enabled, resets it.
///
/// The snapshots will be taken as soon as the value becomes more than [thresholdMb],
/// and saved to the [folder]. The snapshots will be re-taken when the value
/// increases more than by [stepMb], till hitting the [folderSizeLimitMb].
/// The [folder] will be created if it does not exist.
///
/// If [stepMb] is null, only one snapshot will be taken.
///
/// The method checks the folder size before saving snapshot, so the folder
/// may become bigger than [folderSizeLimitMb].
///
/// Use [stopAutoSnapshotOnMemoryOveruse] to stop auto-snapshotting.
void autoSnapshotOnMemoryOveruse({
  required int thresholdMb,
  required int? stepMb,
  required String folder,
  required int folderSizeLimitMb,
  Duration interval = const Duration(seconds: 1),
  VoidCallback? onSnapshot,
}) {}

/// Disables auto-snapshotting if it is enabled by [autoSnapshotOnMemoryOveruse].
void stopAutoSnapshotOnMemoryOveruse() {}
