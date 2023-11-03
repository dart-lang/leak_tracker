// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

import '../shared/_primitives.dart';
import '../shared/_util.dart';
import '../shared/shared_model.dart';
import 'delivery.dart';
import 'messages.dart';
import 'primitives.dart';

bool _extentsionRegistered = false;

/// Registers service extension to signal that leak tracking is
/// already enabled and other leak tracking systems
/// (for example, the one built into Flutter framework)
/// should not be activated.
///
/// If the extension is already registered, returns false.
bool registerLeakTrackingServiceExtension() => _registerServiceExtension(
      (p0, p1) async => ServiceExtensionResponse.result(jsonEncode({})),
    );

/// Registers service extension for DevTools integration.
///
/// If the extension is already registered, returns false.
bool initializeDevToolsIntegration(
  ObjectRef<WeakReference<LeakProvider>?> leakProvider,
) {
  Future<ServiceExtensionResponse> handler(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      assert(method == memoryLeakTrackingExtensionName);

      final theLeakProvider = leakProvider.value?.target;

      if (theLeakProvider == null) {
        return ResponseFromApp(LeakTrackingTurnedOffError())
            .toServiceResponse();
      }

      final request = RequestToApp.fromRequestParameters(parameters).message;

      if (request is RequestForLeakDetails) {
        return ResponseFromApp(theLeakProvider.collectLeaks())
            .toServiceResponse();
      }

      return ResponseFromApp(
        UnexpectedRequestTypeError(request.runtimeType),
      ).toServiceResponse();
    } catch (error, stack) {
      printToConsole(
        'Error handling leak tracking request from DevTools to application.',
      );
      printToConsole(error);
      printToConsole(stack);

      return ResponseFromApp(UnexpectedError(error, stack)).toServiceResponse();
    }
  }

  final result = _registerServiceExtension(handler);

  EventFromApp(LeakTrackingStarted(appLeakTrackerProtocolVersion)).post();

  return result;
}

bool _registerServiceExtension(
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
    // ignore: avoid_catching_errors
  } on ArgumentError catch (ex) {
    // Return false if extension is already registered.
    final isAlreadyRegisteredError = ex.toString().contains('registered');
    if (isAlreadyRegisteredError) {
      return false;
    } else {
      rethrow;
    }
  }
}
