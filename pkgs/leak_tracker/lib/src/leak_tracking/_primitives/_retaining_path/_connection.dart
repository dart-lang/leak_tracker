// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _log = Logger('_connection.dart');

Future<Uri> _serviceUri() async {
  Uri? uri = (await Service.getInfo()).serverWebSocketUri;

  if (uri != null) return uri;

  uri = (await Service.controlWebServer(enable: true)).serverWebSocketUri;

  if (uri == null) {
    throw StateError(
      'Could not start VM service. If you are running `flutter test`, pass the flag `--enable-vmservice`',
    );
  }

  return uri;
}

/// Connects to vm service protocol.
///
/// If the VM service is not found, tries to start it.
Future<VmService> connect() async {
  _log.info('Connecting to VM service protocol...');

  final uri = await _serviceUri();

  final service = await _connectWithWebSocket(uri, _handleError);
  await service.getVersion(); // Warming up and validating the connection.

  _log.info('Connected to vm service protocol.');
  return service;
}

void _handleError(Object? error) {
  _log.info('Error in vm service protocol: $error');
  throw error ?? Exception('Unknown error');
}

Future<VmService> _connectWithWebSocket(
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
