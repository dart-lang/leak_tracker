// // Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.s

import '../shared/shared_model.dart';
import '_object_record.dart';
import '_primitives/model.dart';

/// Decides which leaks to report based on allow lists of the phase.
class LeakFilter {
  final Map<PhaseSettings, _PhaseLeakFilter> _phases = {};

  bool shouldReport(LeakType leakType, ObjectRecord record) {
    final filter =
        _phases.putIfAbsent(record.phase, () => _PhaseLeakFilter(record.phase));
    return filter.shouldReport(leakType, record);
  }
}

class _PhaseLeakFilter {
  _PhaseLeakFilter(this.phase);

  /// Number of leaks by (object type, leak type) for limited allowlists.
  final Map<(String, LeakType), int> _count = <(String, LeakType), int>{};

  final PhaseSettings phase;

  bool shouldReport(LeakType leakType, ObjectRecord record) {
    switch (leakType) {
      case LeakType.notDisposed:
        return _shouldReport(
          leakType,
          record,
          phase.allowAllNotDisposed,
          phase.notDisposedAllowList,
        );
      case LeakType.notGCed:
      case LeakType.gcedLate:
        return _shouldReport(
          leakType,
          record,
          phase.allowAllNotGCed,
          phase.notGCedAllowList,
        );
    }
  }

  bool _shouldReport(
    LeakType leakType,
    ObjectRecord record,
    bool allAllowed,
    Map<String, int?> allowList,
  ) {
    assert(record.phase == phase);
    if (allAllowed) return false;
    final objectType = record.type.toString();
    if (!allowList.containsKey(objectType)) return true;
    final allowedCount = allowList[objectType];
    if (allowedCount == null) return false;

    final actualCount = _count.update(
      (objectType, leakType),
      (value) => value + 1,
      ifAbsent: () => 1,
    );

    if (actualCount <= allowedCount) return false;

    return true;
  }
}
