// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:leak_tracker_flutter_testing/src/test_widgets.dart';

import '../../../test_infra/flutter_classes.dart';

/// Tests with default leak tracking configuration.
///
/// This set of tests verifies that if `testWidgetsWithLeakTracking` is used at least once,
/// leak tracking is configured as expected, and is noop for `testWidgets`.
void main() {
  testWidgetsWithLeakTracking('notGCed leak tracking is off',
      (widgetTester) async {
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });
}
