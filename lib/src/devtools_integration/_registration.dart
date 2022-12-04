// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

import '../_model.dart';
import '../_primitives.dart';
import 'delivery.dart';
import 'messages.dart';
import 'primitives.dart';

bool _extentsionRegistered = false;

/// Registers service extention to signal that leak tracking is
/// already enabled and other leak tracking systems
/// (for example, the one built into Flutter framework)
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
      print('!!!! method: $method');

      final theLeakProvider = leakProvider.value;

      if (theLeakProvider == null) {
        return ResponseFromApp(LeakTrackingTurnedOffError())
            .toServiceResponse();
      }

      final request = RequestToApp.fromRequestParameters(parameters);

      if (request is RequestForLeakDetails) {
        return ResponseFromApp(theLeakProvider.collectLeaks())
            .toServiceResponse();
      }

      return ResponseFromApp(
        UnexpectedRequestTypeError(request.runtimeType),
      ).toServiceResponse();
    } catch (error, stack) {
      print(
        'Error handling leak tracking request from DevTools to application.',
      );
      print(error);
      print(stack);

      return ResponseFromApp(UnexpectedError(error, stack)).toServiceResponse();
    }
  };

  final result = _registerServiceExtention(handler);

  EventFromApp(LeakTrackingStarted(appLeakTrackerProtocolVersion)).post();

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
