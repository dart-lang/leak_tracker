// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/autosnapshotting/_snapshot.dart';
import 'package:test/test.dart';

void main() {
  test('test', () {
    late String actualFileName;

    final returnedFileName = saveSnapshot(
      'folder',
      1,
      snapshotter: (fileName) => actualFileName = fileName,
    );

    expect(returnedFileName, actualFileName);
    expect(returnedFileName, contains('/snapshot-'));
    expect(returnedFileName, endsWith('.json'));
  });
}
