// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:memory_usage/src/auto_snapshotting/_snapshot.dart';
import 'package:test/test.dart';

void main() {
  test('saveSnapshot invokes snapshotter', () {
    late String actualFileName;

    final returnedFileName = saveSnapshot(
      'directory',
      rss: ProcessInfo.currentRss,
      snapshotNumber: 1,
      snapshotter: (fileName) => actualFileName = fileName,
    ).fileName;

    expect(returnedFileName, actualFileName);
    expect(returnedFileName, contains('/snapshot-'));
    expect(returnedFileName, endsWith('.json'));
  });
}
