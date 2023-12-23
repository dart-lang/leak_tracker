import 'package:leak_tracker/src/leak_tracking/primitives/_test_helper_detector.dart';
import 'package:test/test.dart';

class _Test {
  final String stackTrace;
  final bool isHelper;
  final String name;

  _Test({required this.stackTrace, required this.isHelper, required this.name});
}

final _tests = [
  _Test(
    name: 'empty',
    isHelper: false,
    stackTrace: '',
  ),
  _Test(
    name: 'no test helper',
    isHelper: false,
    stackTrace: '''
#0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
#1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:124:35)
#2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:133:6)
#3      new LeakTrackedClass (package:leak_tracker/src/leak_tracking/leak_tracking.dart:10:18)
#4      new StatelessLeakingWidget (package:leak_tracker/src/leak_tracking/leak_tracking.dart:39:27)
#5      main.<anonymous closure> (file:///Users/polinach/_/flutter_dev/packages/flutter_test/test/widget_tester_leaks_test.dart:58:35)
#6      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:183:29)
<asynchronous suspension>
#7      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1017:5)
<asynchronous suspension>
#8      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
''',
  ),
  _Test(
    name: 'test helper, runAsync and pumpWidget',
    isHelper: true,
    stackTrace: '''
#0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
#1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:126:35)
#2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:135:6)
#3      dispatchObjectEvent (package:leak_tracker/src/leak_tracking/primitives/_dispatcher.dart:48:20)
#4      LeakTracking.dispatchObjectEvent.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:103:18)
#5      LeakTracking.dispatchObjectEvent (package:leak_tracker/src/leak_tracking/leak_tracking.dart:109:6)
#6      _dispatchFlutterEventToLeakTracker (package:leak_tracker_flutter_testing/src/testing.dart:73:23)
#7      MemoryAllocations.dispatchObjectEvent (package:flutter/src/foundation/memory_allocations.dart:241:23)
#8      MemoryAllocations._imageOnCreate (package:flutter/src/foundation/memory_allocations.dart:315:5)
#9      new Image._ (dart:ui/painting.dart:1688:15)
#10     Image.clone (dart:ui/painting.dart:1895:18)
#11     createTestImage.<anonymous closure> (package:flutter_test/src/image.dart:42:30)
<asynchronous suspension>
#12     TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:117:7)
<asynchronous suspension>
#13     _AsyncCompleter.complete (dart:async/future_impl.dart:41:3)
<asynchronous suspension>
''',
  ),
  _Test(
    name: 'no test helper, runAsync and pumpWidget',
    isHelper: false,
    stackTrace: '''
#0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
#1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:126:35)
#2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:135:6)
#3      dispatchObjectEvent (package:leak_tracker/src/leak_tracking/primitives/_dispatcher.dart:48:20)
#4      LeakTracking.dispatchObjectEvent.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:103:18)
#5      LeakTracking.dispatchObjectEvent (package:leak_tracker/src/leak_tracking/leak_tracking.dart:109:6)
#6      _dispatchFlutterEventToLeakTracker (package:leak_tracker_flutter_testing/src/testing.dart:73:23)
#7      MemoryAllocations.dispatchObjectEvent (package:flutter/src/foundation/memory_allocations.dart:241:23)
#8      MemoryAllocations._imageOnCreate (package:flutter/src/foundation/memory_allocations.dart:315:5)
#9      new Image._ (dart:ui/painting.dart:1688:15)
#10     Image.clone (dart:ui/painting.dart:1895:18)
#11     createImage.<anonymous closure> (package:myLibrary/src/image.dart:42:30)
<asynchronous suspension>
#12     TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:117:7)
<asynchronous suspension>
#13     _AsyncCompleter.complete (dart:async/future_impl.dart:41:3)
<asynchronous suspension>
''',
  ),
  _Test(
    name: 'test-only GestureRecognizer',
    isHelper: true,
    stackTrace: '''
#0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:69:31)
#1      LeakTracking.dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:126:35)
#2      LeakTracking.dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracking.dart:135:6)
#3      dispatchObjectEvent (package:leak_tracker/src/leak_tracking/primitives/_dispatcher.dart:48:20)
#4      LeakTracking.dispatchObjectEvent.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracking.dart:103:18)
#5      LeakTracking.dispatchObjectEvent (package:leak_tracker/src/leak_tracking/leak_tracking.dart:109:6)
#6      _dispatchFlutterEventToLeakTracker (package:leak_tracker_flutter_testing/src/testing.dart:73:23)
#7      MemoryAllocations.dispatchObjectEvent (package:flutter/src/foundation/memory_allocations.dart:241:23)
#8      MemoryAllocations.dispatchObjectCreated (package:flutter/src/foundation/memory_allocations.dart:275:5)
#9      new GestureRecognizer (package:flutter/src/gestures/recognizer.dart:111:34)
#10     new IndefiniteGestureRecognizer (file:///Users/polinach/_/flutter_dev/packages/flutter/test/gestures/recognizer_test.dart)
#11     main.<anonymous closure>.<anonymous closure> (file:///Users/polinach/_/flutter_dev/packages/flutter/test/gestures/recognizer_test.dart:122:54)
#12     testGesture.<anonymous closure>.<anonymous closure> (file:///Users/polinach/_/flutter_dev/packages/flutter/test/gestures/gesture_tester.dart:31:15)
#13     FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:182:54)
''',
  ),
  _Test(
    name: 'factory method',
    isHelper: true,
    stackTrace: '''
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
''',
  ),
];

void main() {
  for (final t in _tests) {
    test('isCreatedByTestHelper: ${t.name}', () {
      expect(isCreatedByTestHelper(t.stackTrace), t.isHelper);
    });
  }
}
