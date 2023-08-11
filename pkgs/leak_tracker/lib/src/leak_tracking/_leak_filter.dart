// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.s

import '../shared/shared_model.dart';
import '_object_record.dart';
import '_primitives/model.dart';

/// Decides which leaks to report based on allow lists of the phase.
class LeakFilter {
  LeakFilter(this.switches);

  final Map<PhaseSettings, _PhaseLeakFilter> _phases = {};

  final Switches switches;

  bool shouldReport(LeakType leakType, ObjectRecord record) {
    if (_isLeakTypeDisabled(leakType)) return false;

    final filter = _phases.putIfAbsent(
      record.phase,
      () => _PhaseLeakFilter(record.phase),
    );
    return filter.shouldReport(leakType, record);
  }

  bool _isLeakTypeDisabled(LeakType leakType) {
    switch (leakType) {
      case LeakType.notDisposed:
        return switches.disableNotDisposed;
      case LeakType.notGCed:
      case LeakType.gcedLate:
        return switches.disableNotGCed;
    }
  }
}

class _PhaseLeakFilter {
  _PhaseLeakFilter(this.phase);

  /// Number of leaks by (object type, leak type) for limited allowlists.
  final _count = <(String, LeakType), int>{};

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

    return actualCount > allowedCount;
  }
}
