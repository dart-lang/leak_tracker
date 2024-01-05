// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker_testing/leak_tracker_testing.dart';

LeakTesting _trackingOn(LeakTesting settings) {
  final result = settings
      .withTrackedAll()
      .withTracked(allNotDisposed: true, allNotGCed: true);
  return result;
}

final Map<String, LeakTesting Function(LeakTesting settings)>
    leakTestingSettingsCases = {
  'tracking on': _trackingOn,
  // 'tracking off': _trackingOn.withIgnoredAll(),
  // 'notGCed off': _trackingOn.withIgnored(allNotGCed: true),
  // 'notDisposed off': _trackingOn.withIgnored(allNotDisposed: true),
  // 'testHelpers off': _trackingOn.withIgnored(createdByTestHelpers: true),
  // 'creation trace': _trackingOn.withCreationStackTrace(),
  // 'disposal trace': _trackingOn.withDisposalStackTrace(),
  // 'retaining path': _trackingOn.withRetainingPath(),
  // 'all diagnostics': _trackingOn
  //     .withCreationStackTrace()
  //     .withDisposalStackTrace()
  //     .withRetainingPath(),
};
