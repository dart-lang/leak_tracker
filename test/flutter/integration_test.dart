// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/_gc_counter.dart';

import '../test_infra/data/flutter_classes.dart';
import '../test_infra/helpers/gc.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  tearDown(() => disableLeakTracking());

  testWidgets('Leaks in widgets are detected.', (WidgetTester tester) async {
    await tester.runAsync(() async {
      LeakSummary? lastSummary;

      Future<void> _runApp() async {
        enableLeakTracking(
          config: LeakTrackingConfiguration.minimal(
            (summary) => lastSummary = summary,
          ),
        );

        await tester.pumpWidget(StatelessLeakingWidget());
      }

      await _runApp();
      print('!!!! in storage: ${identityHashCode(notGcedStorage.single)}');

      await forceGC(gcCycles: gcCountBuffer);

      await Future.delayed(disposalTimeBuffer);
      checkLeaks();

      //final leaks = collectLeaks();

      print(notGcedStorage.length);
      print('found notGCed: ${lastSummary!.totals[LeakType.notGCed]}');
    });
  });
}
