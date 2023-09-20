// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:leak_tracker/src/leak_tracking/_primitives/_retaining_path/_connection.dart';
import 'package:leak_tracker/src/leak_tracking/_primitives/_retaining_path/_retaining_path.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

class MyClass {
  MyClass();
}

class MyArgClass<T> {
  MyArgClass();
}

final _logs = <String>[];
late StreamSubscription<LogRecord> subscription;

void main() {
  setUpAll(() {
    subscription = Logger.root.onRecord
        .listen((LogRecord record) => _logs.add(record.message));
  });

  setUp(() {
    _logs.clear();
  });

  tearDownAll(() async {
    await subscription.cancel();
  });

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

    await Future.wait(obtainers);

    expect(
      _logs.where((item) => item == 'Connecting to VM service protocol...'),
      hasLength(1),
    );
  });
}
