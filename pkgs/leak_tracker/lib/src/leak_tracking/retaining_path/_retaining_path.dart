// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';

import '_connection.dart';

Future<RetainingPath?> obtainRetainingPath(Type type, int code) async {
  final connection = await connect();

  final fp = _ObjectFingerprint(type, code);
  final theObject = await _objectInIsolate(connection, fp);
  if (theObject == null) return null;

  final result = await connection.service.getRetainingPath(
    theObject.isolateRef.id!,
    theObject.itemId,
    100000,
  );

  return result;
}

class _ObjectFingerprint {
  _ObjectFingerprint(this.type, this.code);

  final Type type;
  final int code;

  String get typeNameWithoutArgs {
    final name = type.toString();
    final index = name.indexOf('<');
    if (index == -1) return name;
    return name.substring(0, index);
  }
}

Future<_ItemInIsolate?> _objectInIsolate(
  Connection connection,
  _ObjectFingerprint object,
) async {
  final classes = await _findClasses(connection, object.typeNameWithoutArgs);

  for (final theClass in classes) {
    // TODO(polina-c): remove when issue is fixed
    // https://github.com/dart-lang/sdk/issues/52893
    if (theClass.name == 'TypeParameters') continue;

    final instances = (await connection.service.getInstances(
          theClass.isolateRef.id!,
          theClass.itemId,
          1000000000,
        ))
            .instances ??
        <ObjRef>[];

    final result = instances.firstWhereOrNull(
      (objRef) =>
          objRef is InstanceRef && objRef.identityHashCode == object.code,
    );
    if (result != null) {
      return _ItemInIsolate(
        isolateRef: theClass.isolateRef,
        itemId: result.id!,
      );
    }
  }

  return null;
}

/// Represents an item in an isolate.
///
/// It can be class or object.
class _ItemInIsolate {
  _ItemInIsolate({required this.isolateRef, required this.itemId, this.name});

  /// The isolate.
  final IsolateRef isolateRef;

  /// Id of the item in the isolate.
  final String itemId;

  /// Name of the item, for debugging purposes.
  final String? name;
}

Future<List<_ItemInIsolate>> _findClasses(
  Connection connection,
  String runtimeClassName,
) async {
  final result = <_ItemInIsolate>[];

  for (final isolate in connection.isolates) {
    var classes = await connection.service.getClassList(isolate.id!);

    const watingTime = Duration(seconds: 2);
    final stopwatch = Stopwatch()..start();

    // In the beginning list of classes may be empty.
    while (classes.classes?.isEmpty ?? true && stopwatch.elapsed < watingTime) {
      await Future.delayed(const Duration(milliseconds: 100));
      classes = await connection.service.getClassList(isolate.id!);
    }
    if (classes.classes?.isEmpty ?? true) {
      throw StateError('Could not get list of classes.');
    }

    final filtered =
        classes.classes?.where((ref) => runtimeClassName == ref.name) ?? [];

    result.addAll(
      filtered.map(
        (classRef) => _ItemInIsolate(
          itemId: classRef.id!,
          isolateRef: isolate,
          name: classRef.name,
        ),
      ),
    );
  }

  return result;
}
