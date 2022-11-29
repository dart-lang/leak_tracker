// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

import '../_model.dart';
import '../_primitives.dart';
import 'from_app.dart';
import 'model.dart';
import 'to_app.dart';

bool _extentsionRegistered = false;

/// Registers service extention to signal that leak tracking is
/// elready enabled and other leak tracking systems
/// (for example, built into Flutter frameworks)
/// should not be activated.
///
/// If the extention is alredy registered, returns false.
bool registerLeakTrackingServiceExtention() => _registerServiceExtention(
      (p0, p1) async => ServiceExtensionResponse.result(jsonEncode({})),
    );

/// Registers service extention for DevTools integration.
///
/// If the extention is alredy registered, returns false.
bool setupDevToolsIntegration(
  ObjectRef<LeakProvider?> leakProvider,
) {
  final handler = (String method, Map<String, String> parameters) async {
    try {
      final event = parseToAppEvent(parameters);

      if (event is RequestForLeakDetails) {
        return serviceResponse(
          ResponseType.success,
          details: 'hello',
        );
      }

      return serviceResponse(
        ResponseType.unexpectedEventType,
        details: event.runtimeType.toString(),
      );
    } catch (error, stack) {
      print(
        'Error handling leak tracking request from DevTools to application.',
      );
      print(error);
      print(stack);
      return serviceResponse(
        ResponseType.unexpectedError,
        details: '$error\n$stack',
      );
    }
  };

  final result = _registerServiceExtention(handler);

  postFromAppEvent(LeakTrackingStarted(appLeakTrackerProtocolVersion));

  return result;
}

bool _registerServiceExtention(
  Future<ServiceExtensionResponse> Function(String, Map<String, String>)
      handler,
) {
  if (_extentsionRegistered) return false;
  try {
    registerExtension(
      memoryLeakTrackingExtensionName,
      handler,
    );
    _extentsionRegistered = true;

    return true;
  } on ArgumentError catch (ex) {
    // Return false if extension is already registered.
    final bool isAlreadyRegisteredError = ex.toString().contains('registered');
    if (isAlreadyRegisteredError) {
      return false;
    } else {
      rethrow;
    }
  }
}
