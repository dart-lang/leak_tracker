// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/devtools_integration/_protocol.dart';
import 'package:leak_tracker/src/devtools_integration/messages.dart';
import 'package:leak_tracker/src/shared/shared_model.dart';
import 'package:test/test.dart';

final messages = [
  // Events from app.
  LeakTrackingStarted('version'),
  LeakSummary({}),

  // Requests to app.
  RequestForLeakDetails(),

  // Successful responses from app.
  Leaks({}),

  // Error responses from app.
  LeakTrackingTurnedOffError(),
  UnexpectedError.fromStrings(error: 'error', stackTrace: 'stackTrace'),
  UnexpectedRequestTypeError.fromString('theType'),
];

void verifyTestsCoverAllEnvelopes() {
  final nonCoveredEnvelopes = Set.of(envelopes.map((e) => e.type));
  for (final message in messages) {
    nonCoveredEnvelopes.remove(message.runtimeType);
  }
  expect(nonCoveredEnvelopes, isEmpty);
}
