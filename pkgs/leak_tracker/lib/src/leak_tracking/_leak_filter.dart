// // Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.s

import '../shared/shared_model.dart';
import '_primitives/model.dart';

/// Decides which leaks to report based on allow lists of the phase.
class LeakFilter {
  final Map<PhaseSettings, _PhaseLeakFilter> _phases = {};

  bool shouldReport(PhaseSettings phase, LeakType leakType, LeakReport leak) {
    final filter = _phases.putIfAbsent(phase, () => _PhaseLeakFilter(phase));
    return filter.shouldReport(leakType, leak);
  }
}

class _PhaseLeakFilter {
  _PhaseLeakFilter(this.phase);

  /// Number of leaks by (object type, leak type) for limited allowlists.
  final Map<(String, LeakType), int> _count = <(String, LeakType), int>{};

  final PhaseSettings phase;

  bool shouldReport(LeakType leakType, LeakReport leak) {
    switch (leakType) {
      case LeakType.notDisposed:
        return _shouldReport(
          leakType,
          leak,
          phase.allowAllNotDisposed,
          phase.notDisposedAllowList,
        );
      case LeakType.notGCed:
      case LeakType.gcedLate:
        return _shouldReport(
          leakType,
          leak,
          phase.allowAllNotGCed,
          phase.notGCedAllowList,
        );
    }
  }

  bool _shouldReport(
    LeakType leakType,
    LeakReport leak,
    bool allAllowed,
    Map<String, int?> allowList,
  ) {
    if (allAllowed) return false;
    final objectType = leak.runtimeType.toString();
    if (!allowList.containsKey(objectType)) return false;
    final allowedCount = allowList[objectType];
    if (allowedCount == null) return false;

    final actualCount = _count.update(
      (objectType, leakType),
      (value) => value + 1,
      ifAbsent: () => 0,
    );

    if (actualCount <= allowedCount) return false;

    return true;
  }
}
