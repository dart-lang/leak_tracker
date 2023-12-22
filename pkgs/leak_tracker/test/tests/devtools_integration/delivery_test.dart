// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:leak_tracker/devtools_integration.dart';
import 'package:leak_tracker/src/devtools_integration/_protocol.dart';
import 'package:test/test.dart';

import '../../test_infra/data/messages.dart';

void main() {
  final messagesByChannel = {
    for (var c in Channel.values)
      c: messages
          .where((m) => envelopeByType(m.runtimeType).channel == c)
          .toList(),
  };

  setUpAll(verifyTestsCoverAllEnvelopes);

  for (final message in messagesByChannel[Channel.eventFromApp]!) {
    test('$EventFromApp serializes ${message.runtimeType}', () {
      final event = EventFromApp(message);
      final serialized = event.messageAsJson();
      final deserialized = EventFromApp.fromJson(serialized);
      expect(event.message.runtimeType, deserialized.message.runtimeType);
    });
  }

  for (final message in messagesByChannel[Channel.requestToApp]!) {
    test('$RequestToApp serializes ${message.runtimeType}', () {
      final request = RequestToApp(message);
      final serialized = request.toRequestParameters();
      final deserialized = RequestToApp.fromRequestParameters(serialized);
      expect(request.message.runtimeType, deserialized.message.runtimeType);
    });
  }

  for (final message in messagesByChannel[Channel.responseFromApp]!) {
    test('$ResponseFromApp serializes ${message.runtimeType}', () {
      final response = ResponseFromApp(message);
      final serialized = response.toJson();
      final deserialized = ResponseFromApp.fromJson(serialized);
      expect(
        response.message.runtimeType,
        deserialized.message.runtimeType,
      );
    });
  }
}
