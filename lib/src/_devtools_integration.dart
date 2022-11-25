// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import '_model.dart';
import '_primitives.dart';
import 'leak_analysis_events.dart';

bool _extentsionRegistered = false;

/// Registers service extention for DevTools integration.
///
/// If the extention is alredy registered, returns false.
bool registerDevToolsIntegration(ObjectRef<LeakProvider?> leakProvider) {
  if (_extentsionRegistered) return false;
  try {
    registerExtension(
      memoryLeakTrackingExtensionName,
      (String method, Map<String, String> parameters) async {
        try {
          final event = parseEvent(parameters);

          if (event is RequestForLeakDetails) {
            return successResponse;
          }

          return errorResponse(
            ResponseErrors.unexpectedEventType,
            event.runtimeType.toString(),
          );
        } catch (error, stack) {
          return errorResponse(
            ResponseErrors.unexpectedError,
            '$error\n$stack',
          );
        }
      },
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
