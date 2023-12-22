// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/devtools_integration/_protocol.dart';
import 'package:test/test.dart';

import '../../test_infra/data/messages.dart';

void main() {
  setUpAll(verifyTestsCoverAllEnvelopes);

  test('each code matches exactly one envelope', () {
    final codesInEnvelopes = Set.of(envelopes.map((e) => e.code));
    expect(codesInEnvelopes, hasLength(Codes.values.length));
  });

  test('envelopes are unique by type', () {
    final types = Set.of(envelopes.map((e) => e.type));
    expect(types, hasLength(envelopes.length));
  });

  for (final message in messages) {
    test('envelopes preserve original type', () {
      final envelope = envelopeByType(message.runtimeType);
      final envelopedMessage = sealEnvelope(message, envelope.channel);
      final openedMessage =
          openEnvelope<Object>(envelopedMessage, envelope.channel);
      expect(openedMessage.runtimeType, message.runtimeType);
    });
  }
}
