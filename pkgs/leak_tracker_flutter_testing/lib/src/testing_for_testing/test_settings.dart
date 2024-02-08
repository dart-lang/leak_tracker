// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker_testing/leak_tracker_testing.dart';

LeakTesting _trackingOn(LeakTesting settings) {
  final result = settings
      .withTrackedAll()
      .withTracked(allNotDisposed: true, experimentalAllNotGCed: true);
  return result;
}

/// Test cases for leak detection settings.
final Map<String, LeakTesting Function(LeakTesting settings)>
    leakTestingSettingsCases = {
  'tracking on': _trackingOn,
  'tracking off': (s) => _trackingOn(s).withIgnoredAll(),
  'notGCed off': (s) => _trackingOn(s).withIgnored(allNotGCed: true),
  'notDisposed off': (s) => _trackingOn(s).withIgnored(allNotDisposed: true),
  'testHelpers off': (s) =>
      _trackingOn(s).withIgnored(createdByTestHelpers: true),
  'testHelpers on': (s) =>
      _trackingOn(s).withTracked(createdByTestHelpers: true),
  'creation trace': (s) => _trackingOn(s).withCreationStackTrace(),
  'disposal trace': (s) => _trackingOn(s).withDisposalStackTrace(),
  'retaining path': (s) => _trackingOn(s).withRetainingPath(),
  'all diagnostics': (s) => _trackingOn(s)
      .withCreationStackTrace()
      .withDisposalStackTrace()
      .withRetainingPath(),
};
