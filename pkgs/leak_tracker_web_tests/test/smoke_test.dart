// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {});

  // Tests that widget testing for web is in general working.
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(Container());
    await tester.runAsync(() async {
      await tester.pump();
    });
  });
}
