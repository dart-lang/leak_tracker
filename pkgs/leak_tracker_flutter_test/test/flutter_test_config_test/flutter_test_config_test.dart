// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import '../test_infra/flutter_classes.dart';
import '../test_infra/leak_tracking_in_flutter.dart';

const test1_tracking_on = 'test1, tracking-on';
const test2_tracking_off = 'test2, tracking-off';

/// Tests for non-mocked public API of leak tracker.
///
/// For this tests `expect` happens in flitter_test_config.dart.
void main() {
  testWidgetsWithLeakTracking(test1_tracking_on, (widgetTester) async {
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgets(test2_tracking_off, (widgetTester) async {
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });
}
