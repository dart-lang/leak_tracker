// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<VmService> connectWithWebSocket(
  Uri uri,
  void Function(Object? error) onError,
) async {
  final ws = WebSocketChannel.connect(uri);
  final stream = ws.stream.handleError(onError);
  final service = VmService(
    stream,
    (String message) {
      ws.sink.add(message);
    },
  );

  if (ws.closeCode != null) {
    onError(ws.closeReason);
    return service;
  }

  return service;
}

/// Executes `callback` for each isolate, and waiting for all callbacks to
/// finish before completing.
Future<void> forEachIsolate(
  VmService service,
  Future<void> Function(IsolateRef) callback,
) async {
  final vm = await service.getVM();
  final futures = <Future>[];
  for (final isolate in vm.isolates ?? []) {
    futures.add(callback(isolate));
  }
  await Future.wait(futures);
}
