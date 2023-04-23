// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'model.dart';

/// Saves a memory heap snapshot of the current process, to the [folder].
///
/// Returns the name of the file where the snapshot was saved.
///
/// The file name contains process id, snapshot number and current RSS.
SnapshotRecord saveSnapshot(
  String folder, {
  required int rss,
  required int snapshotNumber,
  void Function(String fileName) snapshotter =
      NativeRuntime.writeHeapSnapshotToFile,
}) {
  final fileName = path.absolute(
      path.join(folder, 'snapshot-$pid-$snapshotNumber-rss$rss.json'));

  snapshotter(fileName);

  return SnapshotRecord(fileName, snapshotNumber: snapshotNumber, rss: rss);
}
