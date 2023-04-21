// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

void saveSnapshot(String folder, int snapshotNumber) {
  final rss = io.ProcessInfo.currentRss;
  final pid = io.pid;

  final fileName = 'snapshot-$pid-$snapshotNumber-$rss.json';
}
