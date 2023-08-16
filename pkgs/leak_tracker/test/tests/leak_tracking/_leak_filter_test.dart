// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_leak_filter.dart';
import 'package:leak_tracker/src/leak_tracking/_object_record.dart';
import 'package:test/test.dart';

ObjectRecord _stringRecord(PhaseSettings phase) =>
    ObjectRecord(0, {}, String, '', phase);
ObjectRecord _dateTimeRecord(PhaseSettings phase) =>
    ObjectRecord(0, {}, DateTime, '', phase);

void main() {
  test('All leaks are reported with default settings.', () {
    final filter = LeakFilter(const Switches());
    final record = _stringRecord(const PhaseSettings());

    expect(filter.shouldReport(LeakType.notDisposed, record), true);
    expect(filter.shouldReport(LeakType.notGCed, record), true);
    expect(filter.shouldReport(LeakType.gcedLate, record), true);
  });

  test('$LeakFilter respects allowAllNotDisposed.', () {
    final filter = LeakFilter(const Switches());
    final record =
        _stringRecord(const PhaseSettings(allowAllNotDisposed: true));

    expect(filter.shouldReport(LeakType.notDisposed, record), false);
    expect(filter.shouldReport(LeakType.notGCed, record), true);
    expect(filter.shouldReport(LeakType.gcedLate, record), true);
  });

  test('$LeakFilter respects allowAllNotGCed.', () {
    final filter = LeakFilter(const Switches());
    final record = _stringRecord(const PhaseSettings(allowAllNotGCed: true));

    expect(filter.shouldReport(LeakType.notDisposed, record), true);
    expect(filter.shouldReport(LeakType.notGCed, record), false);
    expect(filter.shouldReport(LeakType.gcedLate, record), false);
  });

  test('$LeakFilter respects notGCedAllowList.', () {
    final filter = LeakFilter(const Switches());
    const phase = PhaseSettings(notGCedAllowList: {'String': null});
    final stringRecord = _stringRecord(phase);
    final dateTimeRecord = _dateTimeRecord(phase);

    expect(filter.shouldReport(LeakType.notDisposed, stringRecord), true);
    expect(filter.shouldReport(LeakType.notGCed, stringRecord), false);
    expect(filter.shouldReport(LeakType.gcedLate, stringRecord), false);
    expect(filter.shouldReport(LeakType.notDisposed, dateTimeRecord), true);
    expect(filter.shouldReport(LeakType.notGCed, dateTimeRecord), true);
    expect(filter.shouldReport(LeakType.gcedLate, dateTimeRecord), true);
  });

  test('$LeakFilter respects notDisposedAllowList.', () {
    final filter = LeakFilter(const Switches());
    const phase = PhaseSettings(notDisposedAllowList: {'String': null});
    final stringRecord = _stringRecord(phase);
    final dateTimeRecord = _dateTimeRecord(phase);

    expect(filter.shouldReport(LeakType.notDisposed, stringRecord), false);
    expect(filter.shouldReport(LeakType.notGCed, stringRecord), true);
    expect(filter.shouldReport(LeakType.gcedLate, stringRecord), true);
    expect(filter.shouldReport(LeakType.notDisposed, dateTimeRecord), true);
    expect(filter.shouldReport(LeakType.notGCed, dateTimeRecord), true);
    expect(filter.shouldReport(LeakType.gcedLate, dateTimeRecord), true);
  });

  test('$LeakFilter respects limit.', () {
    final filter = LeakFilter(const Switches());
    const phase = PhaseSettings(notDisposedAllowList: {'String': 2});
    final stringRecord = _stringRecord(phase);
    final dateTimeRecord = _dateTimeRecord(phase);

    expect(filter.shouldReport(LeakType.notDisposed, dateTimeRecord), true);
    expect(filter.shouldReport(LeakType.notDisposed, stringRecord), false);
    expect(filter.shouldReport(LeakType.notDisposed, stringRecord), false);
    expect(filter.shouldReport(LeakType.notDisposed, stringRecord), true);
  });
}
