// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/devtools_integration/_envelopes.dart';
import 'package:test/test.dart';

class _Test<T> {
  _Test(this.message);

  final T message;
}

final _tests = [];

void main() {
  test('each code matches exactly one envelope', () {
    final codesInEnvelopes = Set.from(envelopes.map((e) => e.code));
    expect(codesInEnvelopes, hasLength(Codes.values.length));
  });

  test('envelopes are unique by type', () {
    final types = Set.from(envelopes.map((e) => e.type));
    expect(types, hasLength(envelopes.length));
  });
}
