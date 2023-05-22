// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import '_service.dart';
import '_vm_service_wrapper.dart';

final _log = Logger('MyClassName');

Future<RetainingPath> obtainRetainingPath(Type type, int code) async {
  await _connect();

  final fp = _ObjectFingerprint(type, code);
  final theObject = await _objectInIsolate(fp);
  if (theObject == null) {
    throw Exception('Could not find object in heap');
  }

  _log.info('Requesting retaining path.');
  final result = await _service.getRetainingPath(
    theObject.isolateId,
    theObject.itemId,
    100000,
  );
  _log.info('Recieved retaining path.');
  return result;
}

final List<String> _isolateIds = [];
late VmServiceWrapper _service;
bool _connected = false;

Future<void> _connect() async {
  if (_connected) return;

  final info = await Service.getInfo();
  if (info.serverWebSocketUri == null) {
    throw StateError(
      'Leak troubleshooting is not available in release mode. Run your application or test with flag "--debug" '
      '(Not supported for Flutter yet: https://github.com/flutter/flutter/issues/127331).',
    );
  }

  _service = await connectWithWebSocket(info.serverWebSocketUri!, (error) {
    throw error ?? Exception('Error connecting to service protocol');
  });
  await _service.getVersion();
  await _getIdForTwoIsolates();

  _connected = true;
}

/// Waits for two isolates to be available.
///
/// Depending on environment, isolates may have different names,
/// and there can be one or two. Sometimes the second one appears with latency.
Future<void> _getIdForTwoIsolates() async {
  _log.info('Waiting for two isolates to be available.');
  const isolatesToGet = 2;
  final stopwatch = Stopwatch()..start();
  while (_isolateIds.length < isolatesToGet &&
      stopwatch.elapsed < const Duration(seconds: 2)) {
    _isolateIds.clear();
    await _service
        .forEachIsolate((IsolateRef r) async => _isolateIds.add(r.id!));
    if (_isolateIds.length < isolatesToGet) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  if (_isolateIds.isEmpty) {
    throw StateError('Could not connect to isolates.');
  }
  _log.info('Number of isolates: ${_isolateIds.length}');
}

class _ObjectFingerprint {
  _ObjectFingerprint(this.type, this.code);

  final Type type;
  final int code;
}

Future<_ItemInIsolate?> _objectInIsolate(_ObjectFingerprint object) async {
  final classes = await _findClasses(object.type.toString());

  for (final theClass in classes) {
    final instances = (await _service.getInstances(
          theClass.isolateId,
          theClass.itemId,
          10000000,
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

class _ItemInIsolate {
  _ItemInIsolate({required this.isolateId, required this.itemId});

  final String isolateId;
  final String itemId;
}

Future<List<_ItemInIsolate>> _findClasses(String runtimeClassName) async {
  final result = <_ItemInIsolate>[];

  for (final isolateId in _isolateIds) {
    var classes = await _service.getClassList(isolateId);

    // In the beginning list of classes may be empty.
    while (classes.classes?.isEmpty ?? true) {
      await Future.delayed(const Duration(milliseconds: 100));
      classes = await _service.getClassList(isolateId);
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
