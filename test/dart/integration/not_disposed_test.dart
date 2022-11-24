// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_analysis_model.dart';
import 'package:test/test.dart';

import '../../test_infra/helpers/gc.dart';
import '../../test_infra/mocks/instrumented_class.dart';

void main() {
  tearDown(() => disableLeakTracking());

  test('not disposed object reported', () async {
    LeakSummary? lastSummary;

    void _runApp() {
      enableLeakTracking(
        config: LeakTrackingConfiguration.minimal(
          (summary) => lastSummary = summary,
        ),
      );

      InstrumentedClass();
    }

    _runApp();
    await forceGC();
    expect(lastSummary, isNull);
    checkLeaks();

    expect(lastSummary!.total, 1);
    expect(lastSummary!.totals[LeakType.notDisposed], 1);

    final leaks = collectLeaks();
    expect(leaks.total, 1);

    final theLeak = leaks.notDisposed.first;
    expect(theLeak.trackedClass, contains(InstrumentedClass.library));
    expect(theLeak.trackedClass, contains('$InstrumentedClass'));
  });
}
