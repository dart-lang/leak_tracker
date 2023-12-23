// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<Uri> _serviceUri() async {
  var uri = (await Service.getInfo()).serverWebSocketUri;
  if (uri != null) return uri;

  uri = (await Service.controlWebServer(enable: true)).serverWebSocketUri;
  if (uri != null) return uri;

  throw StateError(
    'Could not start VM service. '
    'If you are running `flutter test`, pass the flag `--enable-vmservice`',
  );
}

/// Connects to vm service protocol.
///
/// If the VM service is not found, tries to start it.
Future<VmService> connect() async {
  final uri = await _serviceUri();

  final service = await vmServiceConnectUri(uri.toString());

  // Warming up and validating the connection.
  await service.getVersion();

  return service;
}
