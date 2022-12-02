// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/devtools_integration/_envelopes.dart';
import 'package:leak_tracker/src/devtools_integration/model.dart';
import 'package:test/test.dart';

final _tests = [
  LeakTrackingStarted('version'),
  LeakSummary({}),
  RequestForLeakDetails(),
  Leaks({}),
];

void verifyTestsCoverAllEnvelopes() {
  final nonCoveredEnvelopes = Set.from(envelopes.map((e) => e.type));
  for (final test in _tests) {
    nonCoveredEnvelopes.remove(test.runtimeType);
  }
  expect(nonCoveredEnvelopes, isEmpty);
}

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

  for (final message in _tests) {
    test('envelopes encoding plus decoding result in original type', () {
      final envelope = envelopeByType(message.runtimeType);
      final encodedMessage = envelope.encode(message);
      final decodedMEssage = envelope.decode(encodedMessage);
      expect(decodedMEssage.runtimeType, message.runtimeType);
    });
  }
}
