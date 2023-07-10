// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:leak_tracker/src/leak_tracking/retaining_path/_connection.dart';
import 'package:leak_tracker/src/leak_tracking/retaining_path/_retaining_path.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide LogRecord;

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

  test('Path for type with generic arg is found.', () async {
    final instance = <int>[1, 2, 3, 4, 5];
    final path = await obtainRetainingPath(MyClass, identityHashCode(instance));
    expect(path!.elements, isNotEmpty);
  });

  ObjRef? _find(List<ObjRef> instances, int code) {
    return instances.firstWhereOrNull(
      (ObjRef objRef) =>
          objRef is InstanceRef && objRef.identityHashCode == code,
    );
  }

  test(
    'Instance of list is found.',
    () async {
      final myClass = MyClass();
      ObjRef? myClassRef;

      final myList = <DateTime>[DateTime.now(), DateTime.now()];
      ObjRef? myListRef;

      final connection = await connect();
      print(connection.isolates.map((i) => '${i.name}-${i.id}'));

      for (final isolate in connection.isolates) {
        var classList = await connection.service.getClassList(isolate.id);
        // In the beginning list of classes may be empty.
        while (classList.classes?.isEmpty ?? true) {
          await Future.delayed(const Duration(milliseconds: 100));
          classList = await connection.service.getClassList(isolate.id);
        }
        if (classList.classes?.isEmpty ?? true) {
          throw StateError('Could not get list of classes.');
        }

        final classes = classList.classes!;

        for (final theClass in classes) {
          print('Checking class ${theClass.name}...');
          // TODO(polina-c): remove when issue is fixed
          // https://github.com/dart-lang/sdk/issues/52893
          if (theClass.name == 'TypeParameters') continue;

          final instances = (await connection.service.getInstances(
                isolate.id,
                theClass.id!,
                1000000000000,
              ))
                  .instances ??
              <ObjRef>[];

          myClassRef ??= _find(instances, identityHashCode(myClass));

          if (myListRef == null) {
            myListRef = _find(instances, identityHashCode(myList));
            if (myListRef != null) {
              print('Found myListRef in ${theClass.name}.');
            }
          }

          if (myClassRef != null && myListRef != null) {
            throw 'Found both instances!!!';
          }
        }
      }

      print('myClassRef: $myClassRef');
      print('myListRef: $myListRef');

      // To make sure [myList] is not const.
      myList.add(DateTime.now());
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
