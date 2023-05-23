// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/testing.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../../dart_test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
void main() {
  tearDown(() => disableLeakTracking());

  test('Retaining path is reported in debug mode.', () async {
    late InstrumentedClass notGCedObject;
    final leaks = await withLeakTracking(
      () async {
        notGCedObject = InstrumentedClass();
        // Dispose reachable instance.
        notGCedObject.dispose();
      },
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectRetainingPathForNonGCed: true,
      ),
      shouldThrowOnLeaks: false,
    );

    expect(() => expect(leaks, isLeakFree), throwsException);
    expect(leaks.total, 1);

    final theLeak = leaks.notGCed.first;
    expect(theLeak.trackedClass, contains(InstrumentedClass.library));
    expect(theLeak.trackedClass, contains('$InstrumentedClass'));
    expect(
      theLeak.context![ContextKeys.retainingPath].runtimeType,
      RetainingPath,
    );
  });
}
