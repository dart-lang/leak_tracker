// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:leak_tracker/src/shared/_formatting.dart';
import 'package:test/test.dart';

const _jsonEmpty = <String, dynamic>{};

const libName = 'libName';
const _json = <String, dynamic>{
  'value': {
    'class': {
      'library': {'name': libName},
    },
  },
};

void main() {
  test('property returns null for no value', () {
    final lib = property(RetainingObjectProperty.lib, _jsonEmpty);
    expect(lib, null);
  });

  test('property extracts value', () {
    final lib = property(RetainingObjectProperty.lib, _json);
    expect(lib, libName);
  });

  test('removeLeakTrackingLines removes lines.', () {
    const stackTrace = '''
#0      ObjectTracker.startTracking (package:leak_tracker/src/leak_tracking/_object_tracker.dart:70:64)
#1      dispatchObjectCreated.<anonymous closure> (package:leak_tracker/src/leak_tracking/leak_tracker.dart:111:13)
#2      dispatchObjectCreated (package:leak_tracker/src/leak_tracking/leak_tracker.dart:118:4)
#3      new LeakTrackedClass (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker/test/test_infra/data/dart_classes.dart:9:5)
#4      new LeakingClass (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker/test/test_infra/data/dart_classes.dart:31:5)
#5      main.<anonymous closure>.<anonymous closure> (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker/test/release/leak_tracking/end_to_end_test.dart:88:9)
#6      withLeakTracking (package:leak_tracker/src/leak_tracking/orchestration.dart:89:19)
#7      main.<anonymous closure> (file:///Users/polinach/_/leak_tracker/pkgs/leak_tracker/test/release/leak_tracking/end_to_end_test.dart:86:25)
#8      Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:215:19)
<asynchronous suspension>
#9      Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:213:7)
<asynchronous suspension>
#10     Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:258:9)
<asynchronous suspension>
''';
    final expected = stackTrace.substring(stackTrace.indexOf('#3'));

    final actual = removeLeakTrackingLines(stackTrace);

    expect(actual, expected);
  });
}
