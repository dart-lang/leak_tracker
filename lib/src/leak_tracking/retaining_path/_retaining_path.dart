// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';

import '_connection.dart';

Future<RetainingPath> obtainRetainingPath(Type type, int code) async {
  final connection = await connect();

  final fp = _ObjectFingerprint(type, code);
  final theObject = await _objectInIsolate(connection, fp);
  if (theObject == null) {
    throw Exception('Could not find object in heap');
  }

  final result = await connection.service.getRetainingPath(
    theObject.isolateId,
    theObject.itemId,
    100000,
  );

  return result;
}

class _ObjectFingerprint {
  _ObjectFingerprint(this.type, this.code);

  final Type type;
  final int code;
}

Future<_ItemInIsolate?> _objectInIsolate(
  Connection connection,
  _ObjectFingerprint object,
) async {
  final classes = await _findClasses(connection, object.type.toString());

  for (final theClass in classes) {
    const pathLengthLimit = 10000000;
    final instances = (await connection.service.getInstances(
          theClass.isolateId,
          theClass.itemId,
          pathLengthLimit,
        ))
            .instances ??
        <ObjRef>[];

    final result = instances.firstWhereOrNull(
      (objRef) =>
          objRef is InstanceRef && objRef.identityHashCode == object.code,
    );
    if (result != null) {
      return _ItemInIsolate(isolateId: theClass.isolateId, itemId: result.id!);
    }
  }

  return null;
}

/// Represents an item in an isolate.
///
/// It can be class or object.
class _ItemInIsolate {
  _ItemInIsolate({required this.isolateId, required this.itemId});

  /// Id of the isolate.
  final String isolateId;

  /// Id of the item in the isolate.
  final String itemId;
}

Future<List<_ItemInIsolate>> _findClasses(
  Connection connection,
  String runtimeClassName,
) async {
  final result = <_ItemInIsolate>[];

  for (final isolateId in connection.isolates) {
    var classes = await connection.service.getClassList(isolateId);

    const watingTime = Duration(seconds: 2);
    final stopwatch = Stopwatch()..start();

    // In the beginning list of classes may be empty.
    while (classes.classes?.isEmpty ?? true && stopwatch.elapsed < watingTime) {
      await Future.delayed(const Duration(milliseconds: 100));
      classes = await connection.service.getClassList(isolateId);
    }
    if (classes.classes?.isEmpty ?? true) {
      throw StateError('Could not get list of classes.');
    }

    final filtered =
        classes.classes?.where((ref) => runtimeClassName == ref.name) ?? [];
    result.addAll(
      filtered.map(
        (classRef) =>
            _ItemInIsolate(itemId: classRef.id!, isolateId: isolateId),
      ),
    );
  }

  return result;
}
