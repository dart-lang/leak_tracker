// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:leak_tracker/src/devtools_integration/_envelopes.dart';
import 'package:test/test.dart';

void main() {
  test('envelopes match codes', () {
    expect(envelopes, hasLength(Codes.values.length));
  });

  test('envelopes are unique by code and type', () {});
}
