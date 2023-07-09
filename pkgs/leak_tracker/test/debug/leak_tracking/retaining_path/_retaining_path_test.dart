// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:leak_tracker/src/leak_tracking/retaining_path/_connection.dart';
import 'package:leak_tracker/src/leak_tracking/retaining_path/_retaining_path.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

class MyClass {
  MyClass();
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
    disconnect();
  });

  tearDownAll(() async {
    await subscription.cancel();
  });

  test('Path for $MyClass instance is found.', () async {
    final instance = MyClass();

    final path = await obtainRetainingPath(MyClass, identityHashCode(instance));
    expect(path!.elements, isNotEmpty);
  });

  test('Path type with generic arg is found.', () async {
    final instance = <int>[1, 2, 3, 4, 5];
    final path = await obtainRetainingPath(MyClass, identityHashCode(instance));
    expect(path!.elements, isNotEmpty);
  });

  test(
    'Instance of array is found.',
    () async {
      final myClass = MyClass();
      final instance = <int>[1, 2, 3, 4, 5];

      final connection = await connect();
      print(connection.isolates.length);
      final isolateId = connection.isolates[0];
      var classList = await connection.service.getClassList(isolateId);

      // In the beginning list of classes may be empty.
      while (classList.classes?.isEmpty ?? true) {
        await Future.delayed(const Duration(milliseconds: 100));
        classList = await connection.service.getClassList(isolateId);
      }
      if (classList.classes?.isEmpty ?? true) {
        throw StateError('Could not get list of classes.');
      }

      final classes = classList.classes!;

      final path = await obtainRetainingPath(
          instance.runtimeType, identityHashCode(instance));
      print(instance);
      instance.add(7);
      expect(path!.elements, isNotEmpty);

      // To make sure instance is not const.
      instance.add(6);
      instance.add(7);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );

  test('Connection is happening just once', () async {
    final instance1 = MyClass();
    final instance2 = MyClass();

    final obtainers = [
      obtainRetainingPath(MyClass, identityHashCode(instance1)),
      obtainRetainingPath(MyClass, identityHashCode(instance2)),
    ];

    await Future.wait(obtainers);

    expect(
      _logs.where((item) => item == 'Connecting to vm service protocol...'),
      hasLength(1),
    );
  });
}
