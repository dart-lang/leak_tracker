// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A record of a taken snapshot.
class SnapshotRecord {
  SnapshotRecord(this.fileName, this.snapshotNumber, this.rss);

  final String fileName;
  final int snapshotNumber;
  final int rss;
}
