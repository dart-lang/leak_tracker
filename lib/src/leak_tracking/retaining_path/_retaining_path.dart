// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';

import '_service.dart';
import '_vm_service_wrapper.dart';

Future<RetainingPath> obtainRetainingPath(Type type, int code) async {
  await _connect();

  final fp = _ObjectFingerprint(type, code);
  final targetId = await _targetId(fp);
  if (targetId == null) {
    throw Exception('Could not find object in heap');
  }

  return await _service.getRetainingPath(_isolateId, targetId, 100000);
}

late String _isolateId;
late VmServiceWrapper _service;
bool _connected = false;

Future<void> _connect() async {
  if (_connected) return;

  final info = await Service.getInfo();
  if (info.serverWebSocketUri == null) {
    throw StateError(
      'Leak troubleshooting is not available in release mode. Run your application or test in debug or profile mode.',
    );
  }

  _service = await connectWithWebSocket(info.serverWebSocketUri!, (error) {
    throw error ?? Exception('Error connecting to service protocol');
  });

  await _service.getVersion();
  await _service.forEachIsolate((IsolateRef r) async {
    if (r.name == 'main') {
      _isolateId = r.id!;
    }
  });

  _connected = true;
}

class _ObjectFingerprint {
  _ObjectFingerprint(this.type, this.code);

  final Type type;
  final int code;
}

Future<String?> _targetId(_ObjectFingerprint object) async {
  final classes = await findClasses(object.type.toString());

  for (final theClass in classes) {
    final instances =
        (await _service.getInstances(_isolateId, theClass.id!, 10000000))
                .instances ??
            <ObjRef>[];
    final result = instances.firstWhereOrNull(
      (objRef) =>
          objRef is InstanceRef && objRef.identityHashCode == object.code,
    );
    if (result != null) return result.id;
  }

  return null;
}

Future<List<ClassRef>> findClasses(String runtimeClassName) async {
  final classes = await _service.getClassList(_isolateId);
  return classes.classes
          ?.where((ref) => runtimeClassName == ref.name)
          .toList() ??
      [];
}
