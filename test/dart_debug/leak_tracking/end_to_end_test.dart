// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_formatting.dart';
import 'package:leak_tracker/testing.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../../dart_test_infra/data/dart_classes.dart';

/// Tests for non-mocked public API of leak tracker.
void main() {
  tearDown(() => disableLeakTracking());

  test('Retaining path for not GCed object is reported.', () async {
    final leaks = await withLeakTracking(
      () async {
        LeakingClass();
      },
      shouldThrowOnLeaks: false,
      leakDiagnosticConfig: const LeakDiagnosticConfig(
        collectRetainingPathForNonGCed: true,
      ),
    );

    const expectedRetainingPath = [
      'leak_tracker/test/dart_test_infra/data/dart_classes.dart/_notGCedObjects',
      'dart.core/_GrowableList:0',
      'leak_tracker/test/dart_test_infra/data/dart_classes.dart/LeakTrackedClass',
    ];

    expect(leaks.total, 1);
    expect(
      () => expect(leaks, isLeakFree),
      throwsA(
        predicate(
          (e) {
            if (e is! TestFailure) {
              throw 'Unexpected exception type: ${e.runtimeType}';
            }
            verifyRetainignPath(expectedRetainingPath, e.message!);
            return true;
          },
        ),
      ),
    );

    final theLeak = leaks.notGCed.first;
    expect(theLeak.trackedClass, contains(LeakTrackedClass.library));
    expect(theLeak.trackedClass, contains('$LeakTrackedClass'));
  });
}

void verifyRetainignPath(
    List<String> expectedRetainingPath, String actualMessage) {
  int previousIndex = 0;
  for (var i = 0; i < expectedRetainingPath.length; i++) {
    final index = actualMessage.indexOf('${expectedRetainingPath[i]}\n');
    expect(index > previousIndex, true);
    previousIndex = index;
  }
}
