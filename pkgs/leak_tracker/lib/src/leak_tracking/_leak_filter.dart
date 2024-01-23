// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.s

import '../shared/shared_model.dart';
import '_object_record.dart';
import 'primitives/model.dart';

/// Decides which leaks to report based on allow lists of the phase.
class LeakFilter {
  final Map<PhaseSettings, _PhaseLeakFilter> _phases = {};

  /// Returns true if the leak should be reported.
  ///
  /// If result is true, removes [ContextKeys.startCallstack]
  /// from [ObjectRecord.context] the call stack
  /// is not needed for debugging, but only needed to detect if the leak
  /// should be ignored.
  bool shouldReport(LeakType leakType, ObjectRecord record) {
    final filter = _phases.putIfAbsent(
      record.phase,
      () => _PhaseLeakFilter(record.phase),
    );
    return filter.shouldReport(leakType, record);
  }
}

class _PhaseLeakFilter {
  _PhaseLeakFilter(this.phase);

  /// Number of leaks by (object type, leak type) for limited allowlists.
  final _count = <(String, LeakType), int>{};

  final PhaseSettings phase;

  bool shouldReport(LeakType leakType, ObjectRecord record) {
    final bool result;
    switch (leakType) {
      case LeakType.notDisposed:
        result = _shouldReportByTypeAndClass(
          leakType,
          record,
          phase.ignoredLeaks.notDisposed,
        );
      case LeakType.notGCed:
      case LeakType.gcedLate:
        return result = _shouldReportByTypeAndClass(
          leakType,
          record,
          phase.ignoredLeaks.notGCed,
        );
    }

    // Check for test helpers should happen only in case of leak because
    // it is performance heavy.
    bool shouldCheckForTestHelpers =
        phase.ignoredLeaks.createdByTestHelpers && result;

    if (!shouldCheckForTestHelpers) return result;

    // if (!phase.ignoredLeaks.createdByTestHelpers || !result) return result;

    final stackTrace =
        record.context![ContextKeys.startCallstack]! as StackTrace;

    if (!phase.leakDiagnosticConfig.collectStackTraceOnStart) {
      record.context!.remove(ContextKeys.startCallstack);
    }
  }

  bool _shouldReportByTypeAndClass(
    LeakType leakType,
    ObjectRecord record,
    IgnoredLeaksSet ignoredLeaks,
  ) {
    assert(record.phase == phase);
    if (ignoredLeaks.ignoreAll) return false;
    final objectType = record.type.toString();
    if (!ignoredLeaks.byClass.containsKey(objectType)) return true;
    final allowedCount = ignoredLeaks.byClass[objectType];
    if (allowedCount == null) return false;

    final actualCount = _count.update(
      (objectType, leakType),
      (value) => value + 1,
      ifAbsent: () => 1,
    );

    return actualCount > allowedCount;
  }
}
