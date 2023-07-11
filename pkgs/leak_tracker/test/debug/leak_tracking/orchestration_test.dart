// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:test/test.dart';

class MyClass {
  MyClass();

  final Stopwatch stopwatch = Stopwatch();
  WeakReference<Stopwatch> get ref => WeakReference(stopwatch);
}

void main() {
  final myObject = MyClass();
  test('formattedRetainingPath returns path', () async {
    final path = await formattedRetainingPath(myObject.ref);
    expect(path, contains('_test.dart/MyClass:stopwatch'));
  });
}
