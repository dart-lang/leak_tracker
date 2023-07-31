// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_leak_filter.dart';
import 'package:leak_tracker/src/leak_tracking/_object_record.dart';
import 'package:test/test.dart';

void main() {
  test('All leaks are reported with default settings.', () {
    final filter = LeakFilter();
    final record = ObjectRecord(0, {}, String, '', const PhaseSettings());

    expect(filter.shouldReport(LeakType.notDisposed, record), true);
    expect(filter.shouldReport(LeakType.notGCed, record), true);
    expect(filter.shouldReport(LeakType.gcedLate, record), true);
  });
}
