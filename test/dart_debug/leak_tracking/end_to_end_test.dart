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

  test('Retaining path for not GCed object is reported.', () async {
    late LeakTrackedClass notGCedObject;
    final leaks = await withLeakTracking(
      () async {
        notGCedObject = LeakTrackedClass();
        // Dispose reachable instance.
        notGCedObject.dispose();
      },
      shouldThrowOnLeaks: false,
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectRetainingPathForNonGCed: true,
      ),
    );

    expect(leaks.total, 1);
    expect(
      () => expect(leaks, isLeakFree),
      throwsA(
        predicate(
          (e) {
            return e is TestFailure &&
                e.toString().contains(
                      'leak_tracker/test/dart_test_infra/data/dart_classes.dart/LeakTrackedClass',
                    );
          },
        ),
      ),
    );

    final theLeak = leaks.notGCed.first;
    expect(theLeak.trackedClass, contains(LeakTrackedClass.library));
    expect(theLeak.trackedClass, contains('$LeakTrackedClass'));
    expect(
      theLeak.context![ContextKeys.retainingPath].runtimeType,
      RetainingPath,
    );
  });
}
