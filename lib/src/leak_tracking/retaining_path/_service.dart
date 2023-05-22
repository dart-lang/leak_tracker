// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '_vm_service_wrapper.dart';

Future<VmServiceWrapper> connectWithWebSocket(
  Uri uri,
  void Function(Object? error) onError,
) async {
  final ws = WebSocketChannel.connect(uri);
  final stream = ws.stream.handleError(onError);
  final service = VmServiceWrapper.fromNewVmService(
    stream,
    (String message) {
      ws.sink.add(message);
    },
    uri,
  );

  if (ws.closeCode != null) {
    onError(ws.closeReason);
    return service;
  }

  return service;
}
