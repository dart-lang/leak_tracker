// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Frames pointing the folder `test` or the package `flutter_test`.
const _testHelperFrame = r'(?:\/test\/|\(package:flutter_test\/)';

/// Stack frame, containing this string, is start of a test.
///
/// There are many spaces to make RegEx faster.
const _testStartFrame = r'      main.<anonymous closure> \(file:\/\/\/';

const _anyText = r'[\S\s]*';

final _expr =
    RegExp('$_testHelperFrame$_anyText$_testStartFrame', multiLine: true);

bool isCreatedByTestHelper(StackTrace trace) {
  return _expr.hasMatch(trace.toString());
}

// #0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
// #1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:124:35)
// #2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:133:6)
// #3      new LeakTrackedClass (package:leak_tracker_flutter_testing/src/test_classes.dart:40:18)
// #4      new StatelessLeakingWidget (package:leak_tracker_flutter_testing/src/test_classes.dart:20:27)
// #5      main.<anonymous closure> (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end/test_helpers_test.dart:30:5)
// #6      Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:215:19)
// <asynchronous suspension>
// #7      Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:213:7)
// <asynchronous suspension>
// #8      Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:258:9)
// <asynchronous suspension>

// #0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
// #1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:124:35)
// #2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:133:6)
// #3      new LeakTrackedClass (package:leak_tracker_flutter_testing/src/test_classes.dart:40:18)
// #4      new StatelessLeakingWidget (package:leak_tracker_flutter_testing/src/test_classes.dart:24:33)
// #5      main.<anonymous closure> (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end/test_helpers_test.dart:30:5)
// #6      Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:215:19)
// <asynchronous suspension>
// #7      Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:213:7)
// <asynchronous suspension>
// #8      Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:258:9)
// <asynchronous suspension>

// ✓ Prod leak is detected.
// #0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
// #1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:124:35)
// #2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:133:6)
// #3      new LeakTrackedClass (package:leak_tracker_flutter_testing/src/test_classes.dart:40:18)
// #4      new StatelessLeakingWidget (package:leak_tracker_flutter_testing/src/test_classes.dart:20:27)
// #5      createTestWidget (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end/test_helpers_test.dart:46:46)
// #6      main.<anonymous closure> (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end/test_helpers_test.dart:38:5)
// #7      Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:215:19)
// <asynchronous suspension>
// #8      Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:213:7)
// <asynchronous suspension>
// #9      Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:258:9)
// <asynchronous suspension>

// #0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
// #1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:124:35)
// #2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:133:6)
// #3      new LeakTrackedClass (package:leak_tracker_flutter_testing/src/test_classes.dart:40:18)
// #4      new StatelessLeakingWidget (package:leak_tracker_flutter_testing/src/test_classes.dart:24:33)
// #5      createTestWidget (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end/test_helpers_test.dart:46:46)
// #6      main.<anonymous closure> (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end/test_helpers_test.dart:38:5)
// #7      Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:215:19)
// <asynchronous suspension>
// #8      Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:213:7)
// <asynchronous suspension>
// #9      Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:258:9)
// <asynchronous suspension>

