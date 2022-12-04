// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/devtools_integration/_envelopes.dart';
import 'package:leak_tracker/src/devtools_integration/messages.dart';
import 'package:leak_tracker/src/model.dart';
import 'package:test/test.dart';

import '../../test_infra/data/messages.dart';

void main() {
  setUp(() {
    verifyTestsCoverAllEnvelopes();
  });

  test('each code matches exactly one envelope', () {
    final codesInEnvelopes = Set.from(envelopes.map((e) => e.code));
    expect(codesInEnvelopes, hasLength(Codes.values.length));
  });

  test('envelopes are unique by type', () {
    final types = Set.from(envelopes.map((e) => e.type));
    expect(types, hasLength(envelopes.length));
  });

  for (final message in messages) {
    test('envelopes preserve original type', () {
      final envelope = envelopeByType(message.runtimeType);
      final envelopedMessage = Envelope.seal(message, envelope.channel);
      final openedMessage = Envelope.open(envelopedMessage, envelope.channel);
      expect(openedMessage.runtimeType, message.runtimeType);
    });
  }
}
