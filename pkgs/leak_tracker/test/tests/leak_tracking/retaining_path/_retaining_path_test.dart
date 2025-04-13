// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:leak_tracker/src/leak_tracking/primitives/_retaining_path/_connection.dart';
import 'package:leak_tracker/src/leak_tracking/primitives/_retaining_path/_retaining_path.dart';
import 'package:test/test.dart';

class MyClass {
  MyClass();
}

class MyArgClass<T> {
  MyArgClass();
}

void main() {
  test('Path for $MyClass instance is found.', () async {
    final instance = MyClass();
    final connection = await connect();

    final path = await retainingPath(
      connection,
      instance,
    );

    expect(path!.elements, isNotEmpty);
  });

  test('Path for class with generic arg is found.', () async {
    final instance = MyArgClass<String>();
    final connection = await connect();

    final path = await retainingPath(
      connection,
      instance,
    );
    expect(path!.elements, isNotEmpty);
  });

  test('Connection can be reused', () async {
    final instance1 = MyClass();
    final instance2 = MyClass();
    final connection = await connect();

    final obtainers = [
      retainingPath(connection, instance1),
      retainingPath(connection, instance2),
    ];

    final result = await Future.wait(obtainers);

    expect(result.where((p) => p == null), hasLength(0));
  });
}
