// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:leak_tracker/leak_analysis.dart';
import 'package:test/test.dart';

void main() {
  test('$Leaks serializes.', () {
    final leaks = Leaks({});

    final json = leaks.toJson();

    expect(
      jsonEncode(json),
      jsonEncode(Leaks.fromJson(json).toJson()),
    );
  });

  test('$LeakSummary serializes.', () {
    final leakSummary = LeakSummary({
      LeakType.gcedLate: 2,
      LeakType.notDisposed: 3,
      LeakType.notGCed: 4,
    });

    final json = leakSummary.toJson();

    expect(
      jsonEncode(json),
      jsonEncode(LeakSummary.fromJson(json).toJson()),
    );
  });
}
