// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import '_service.dart';

final _log = Logger('_retaining_path.dart');

Future<RetainingPath> obtainRetainingPath(Type type, int code) async {
  await _connect();

  final fp = _ObjectFingerprint(type, code);
  final theObject = await _objectInIsolate(fp);
  if (theObject == null) {
    throw Exception('Could not find object in heap');
  }

  _log.info('Requesting retaining path.');

  await Future.delayed(const Duration(milliseconds: 1000));

  await _theService.checkRequests();

  final result = await _theService.getRetainingPath(
    theObject.isolateId,
    theObject.itemId,
    100000,
  );

  await _theService.checkRequests();

  _log.info('Recieved retaining path.');
  return result;
}

final List<String> _isolateIds = [];
late VmService _theService;
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

  _theService = await connectWithWebSocket(info.serverWebSocketUri!, (error) {
    throw error ?? Exception('Error connecting to service protocol');
  });
  await _theService.getVersion();
  await _getIdForTwoIsolates();

  _connected = true;
}

/// Tries to wait for two isolates to be available.
///
/// Depending on environment (command line / IDE, Flutter / Dart), isolates may have different names,
/// and there can be one or two. Sometimes the second one appears with latency.
/// And sometimes there are two isolates with name 'main'.
Future<void> _getIdForTwoIsolates() async {
  _log.info('Waiting for two isolates to be available.');
  const isolatesToGet = 2;
  const watingTime = Duration(seconds: 2);
  final stopwatch = Stopwatch()..start();
  while (_isolateIds.length < isolatesToGet && stopwatch.elapsed < watingTime) {
    _isolateIds.clear();
    await forEachIsolate(
      _theService,
      (IsolateRef r) async => _isolateIds.add(r.id!),
    );
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
    const pathLengthLimit = 10000000;
    final instances = (await _theService.getInstances(
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

Future<List<_ItemInIsolate>> _findClasses(String runtimeClassName) async {
  final result = <_ItemInIsolate>[];

  for (final isolateId in _isolateIds) {
    var classes = await _theService.getClassList(isolateId);

    const watingTime = Duration(seconds: 2);
    final stopwatch = Stopwatch()..start();

    // In the beginning list of classes may be empty.
    while (classes.classes?.isEmpty ?? true && stopwatch.elapsed < watingTime) {
      await Future.delayed(const Duration(milliseconds: 100));
      classes = await _theService.getClassList(isolateId);
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
