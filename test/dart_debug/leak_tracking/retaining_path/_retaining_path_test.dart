// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/leak_tracking/retaining_path/_retaining_path.dart';
import 'package:test/test.dart';

class MyClass {
  MyClass();
}

void main() {
  test('$MyClass instance can be found.', () async {
    final instance = MyClass();

    final path = await obtainRetainingPath(MyClass, identityHashCode(instance));
    expect(path.elements, isNotEmpty);
  });
}
