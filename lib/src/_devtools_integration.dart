// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'leak_analysis_events.dart';
import 'leak_analysis_model.dart';

bool registerServiceExtension(LeakProvider provider) {
  try {
    registerExtension(
      memoryLeakTrackingExtensionName,
      (String method, Map<String, String> parameters) async {
        final event = parseEvent(parameters);

        if (event is RequestForLeakDetails) {
          return ServiceExtensionResponse.result('{}');
        }

        final bool isRequestForDetails =
            parameters.containsKey('requestDetails');
        if (isRequestForDetails) reportLeaks(leakTracker.collectLeaks());

        return ServiceExtensionResponse.result('{}');
      },
    );

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
