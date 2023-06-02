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

  test('$MyClass instance can be found.', () async {
    final instance = MyClass();

    final path = await obtainRetainingPath(MyClass, identityHashCode(instance));
    expect(path.elements, isNotEmpty);
  });

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
