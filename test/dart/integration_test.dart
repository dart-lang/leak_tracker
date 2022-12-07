// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/_gc_counter.dart';
import 'package:test/test.dart';

import '../test_infra/helpers/gc.dart';
import '../test_infra/mocks/instrumented_class.dart';

/// Tests for non-mocked public API of leak tracker.
///
/// Can serve as examples for regression leak-testing for Flutter widgets.
void main() {
  tearDown(() => disableLeakTracking());

  test('Not disposed object reported.', () async {
    LeakSummary? lastSummary;

    void _runApp() {
      enableLeakTracking(
        config: LeakTrackingConfiguration.minimal(
          (summary) => lastSummary = summary,
        ),
      );

      // Create and not dispose an inastance of instrumented class.
      InstrumentedClass();
    }

    _runApp();
    await forceGC(gcCycles: gcCountBuffer);
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

  test('Not GCed object reported.', () async {
    LeakSummary? lastSummary;

    late InstrumentedClass notGCedObject;
    void _runApp() {
      enableLeakTracking(
        config: LeakTrackingConfiguration.minimal(
          (summary) => lastSummary = summary,
        ),
      );

      notGCedObject = InstrumentedClass();
      // Dispose reachable instance.
      notGCedObject.dispose();
    }

    _runApp();
    await forceGC(gcCycles: gcCountBuffer);
    expect(lastSummary, isNull);
    checkLeaks();

    expect(lastSummary!.total, 1);
    expect(lastSummary!.totals[LeakType.notGCed], 1);

    final leaks = collectLeaks();
    expect(leaks.total, 1);

    final theLeak = leaks.notGCed.first;
    expect(theLeak.trackedClass, contains(InstrumentedClass.library));
    expect(theLeak.trackedClass, contains('$InstrumentedClass'));
  });
}
