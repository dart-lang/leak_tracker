// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/src/leak_tracking/_formatting.dart';

const _jsonEmpty = <String, dynamic>{};

const libName = 'libName';
const _json = <String, dynamic>{
  'value': {
    'class': {
      'library': {'name': libName}
    }
  }
};

void main() {
  test('property returns null for no value', () {
    final lib = property(RetainingObjectProperty.lib, _jsonEmpty);
    expect(lib, null);
  });

  test('property extracts value', () {
    final lib = property(RetainingObjectProperty.lib, _json);
    expect(lib, libName);
  });
}
