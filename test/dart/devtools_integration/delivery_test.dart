// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:leak_tracker/devtools_integration.dart';
import 'package:leak_tracker/src/devtools_integration/_envelopes.dart';
import 'package:leak_tracker/src/devtools_integration/messages.dart';
import 'package:leak_tracker/src/model.dart';
import 'package:test/test.dart';

import '../../test_infra/data/messages.dart';

void main() {
  setUp(() {
    verifyTestsCoverAllEnvelopes();
  });

  for (final message in messages) {
    test('delivery vehicles serialization works', () {
      final envelope = envelopeByType(message.runtimeType);

      switch (envelope.channel) {
        case Channel.requestToApp:
          final request = RequestToApp(message);
          final serialized = request.toRequestParameters();
          final deserialized = RequestToApp.fromRequestParameters(serialized);
          expect(request.message.runtimeType, deserialized.message.runtimeType);
          break;
        case Channel.eventFromApp:
          final event = EventFromApp(message);
          final serialized = event.messageAsJson();
          final deserialized = EventFromApp.fromJson(serialized);
          expect(event.message.runtimeType, deserialized.message.runtimeType);
          break;
        case Channel.responseFromApp:
          final response = ResponseFromApp(message);
          final serialized = response.toJson();
          final deserialized = ResponseFromApp.fromJson(serialized);
          expect(
            response.message.runtimeType,
            deserialized.message.runtimeType,
          );
          break;
      }
    });
  }
}
