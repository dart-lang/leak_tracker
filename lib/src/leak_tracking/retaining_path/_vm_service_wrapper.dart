// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Code needs to match API from VmService.

library vm_service_wrapper;

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import '_json_to_service_cache.dart';

class VmServiceWrapper implements VmService {
  VmServiceWrapper.fromNewVmService(
    Stream<dynamic> /*String|List<int>*/ inStream,
    void Function(String message) writeMessage,
    this._connectedUri, {
    Log? log,
    DisposeHandler? disposeHandler,
  }) {
    _vmService = VmService(
      inStream,
      writeMessage,
      log: log,
      disposeHandler: disposeHandler,
    );
  }

  late final VmService _vmService;

  Uri get connectedUri => _connectedUri;
  final Uri _connectedUri;

  // A local cache of "fake" service objects. Used to convert JSON objects to
  // VM service response formats to be used with APIs that require them.
  final fakeServiceCache = JsonToServiceCache();

  /// Executes `callback` for each isolate, and waiting for all callbacks to
  /// finish before completing.
  Future<void> forEachIsolate(
    Future<void> Function(IsolateRef) callback,
  ) async {
    final vm = await _vmService.getVM();
    final futures = <Future>[];
    for (final isolate in vm.isolates ?? []) {
      futures.add(callback(isolate));
    }
    await Future.wait(futures);
  }

  @override
  Future<Version> getVersion() async => _vmService.getVersion();

  @override
  Future<RetainingPath> getRetainingPath(
    String isolateId,
    String targetId,
    int limit,
  ) =>
      _vmService.getRetainingPath(isolateId, targetId, limit);

  /// Prevent DevTools from blocking Dart SDK rolls if changes in
  /// package:vm_service are unimplemented in DevTools.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
