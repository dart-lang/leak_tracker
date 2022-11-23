// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/_leak_checker.dart';
import 'package:leak_tracker/src/leak_analysis_model.dart';
import 'package:test/test.dart';

// Enum-like static classes are ok.
// ignore: avoid_classes_with_only_static_members
class _SummaryValues {
  static void verifyValues() {
    expect(zero.toMessage(), isNot(nonZero.toMessage()));
    expect(nonZero.toMessage(), nonZeroCopy.toMessage());
  }

  static const zero = LeakSummary({});

  static const nonZero = LeakSummary({
    LeakType.gcedLate: 1,
    LeakType.notDisposed: 2,
    LeakType.notGCed: 3,
  });

  static late final nonZeroCopy =
      LeakSummary(<LeakType, int>{}..addAll(nonZero.totals));
}

void main() {
  late _MockLeakProvider leakProvider;

  late _MockStdoutSink stdout;
  late _MockDevToolsSink devtools;
  late _ListenedSink listened;

  const period = Duration(milliseconds: 5);
  late final doublePeriod = Duration(microseconds: period.inMicroseconds);

  LeakChecker leakChecker({
    required bool checkPeriodically,
    required bool hasListener,
    required bool hasStdout,
    required bool hasDevtools,
  }) =>
      LeakChecker(
        leakProvider: leakProvider,
        checkPeriod: checkPeriodically ? period : null,
        leakListener:
            hasListener ? (summary) => listened.store.add(summary) : null,
        stdoutSink: hasStdout ? stdout : null,
        devToolsSink: hasDevtools ? devtools : null,
      );

  LeakChecker defaultLeakChecker() => leakChecker(
        checkPeriodically: true,
        hasListener: false,
        hasStdout: true,
        hasDevtools: true,
      );

  setUp(() {
    leakProvider = _MockLeakProvider();

    stdout = _MockStdoutSink();
    devtools = _MockDevToolsSink();
    listened = _ListenedSink();
  });

  test('Mocks emulate production well.', () {
    _SummaryValues.verifyValues();

    // Mock defaults match real configuration defaults.
    final config = LeakTrackingConfiguration();
    final checker = defaultLeakChecker();
    expect(config.notifyDevTools, checker.devToolsSink != null);
    expect(config.stdoutLeaks, checker.stdoutSink != null);
    expect(config.leakListener == null, checker.leakListener == null);
    expect(config.checkPeriod == null, checker.checkPeriod == null);
  });

  test('Default checker sends leaks to stdout and devtools.', () async {
    // ignore: unused_local_variable
    final checker = defaultLeakChecker();

    // Make sure there is no leaks.
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);

    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);

    // Report leaks and make sure they signaled one time.
    leakProvider.value = _SummaryValues.nonZero;
    await Future.delayed(doublePeriod);
    stdout.checkAndClear(_SummaryValues.nonZero);
    devtools.checkAndClear(_SummaryValues.nonZero);

    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);

    // Report the same leak totals and make sure there is no signals.
    leakProvider.value = _SummaryValues.nonZeroCopy;
    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);

    // Drop totals and check signal.
    leakProvider.value = _SummaryValues.zero;
    await Future.delayed(doublePeriod);
    stdout.checkAndClear(_SummaryValues.zero);
    devtools.checkAndClear(_SummaryValues.zero);

    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
  });

  test('Listener-only checker sends leaks to just listener.', () async {
    // ignore: unused_local_variable
    final checker = leakChecker(
      hasDevtools: false,
      hasStdout: false,
      hasListener: true,
      checkPeriodically: true,
    );

    // Make sure there is no leaks.
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    expect(listened.store, isEmpty);

    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    expect(listened.store, isEmpty);

    // Report leaks and make sure they signaled one time.
    leakProvider.value = _SummaryValues.nonZero;
    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    listened.checkAndClear(_SummaryValues.nonZero);

    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    expect(listened.store, isEmpty);

    // Report the same leak totals and make sure there is no signals.
    leakProvider.value = _SummaryValues.nonZeroCopy;
    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    expect(listened.store, isEmpty);

    // Drop totals and check signal.
    leakProvider.value = _SummaryValues.zero;
    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    listened.checkAndClear(_SummaryValues.zero);

    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    expect(listened.store, isEmpty);
  });

  test('No-timer checker sends leaks when checked.', () async {
    // ignore: unused_local_variable
    final checker = leakChecker(
      checkPeriodically: false,
      hasDevtools: true,
      hasStdout: true,
      hasListener: true,
    );

    // Make sure there is no leaks.
    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    expect(listened.store, isEmpty);

    // Report leaks and make sure did not signal.
    leakProvider.value = _SummaryValues.nonZero;
    await Future.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(devtools.store, isEmpty);
    expect(listened.store, isEmpty);

    // Check leaks and make sure they signaled one time.
    checker.checkLeaks();
    stdout.checkAndClear(_SummaryValues.nonZero);
    devtools.checkAndClear(_SummaryValues.nonZero);
    listened.checkAndClear(_SummaryValues.nonZero);
  });
}

class _ListenedSink {
  final store = <LeakSummary>[];

  void checkAndClear(LeakSummary summary) {
    expect(store, hasLength(1));
    expect(store.first.matches(summary), isTrue);
    store.clear();
  }
}

class _MockStdoutSink implements StdoutSink {
  final store = <String>[];

  @override
  void print(String content) => store.add(content);

  void checkAndClear(LeakSummary summary) {
    expect(store, hasLength(1));
    expect(store.first, contains(summary.toMessage()));
    store.clear();
  }
}

class _MockDevToolsSink implements DevToolsSink {
  final store = <LeakSummary>[];

  @override
  void send(Map<String, dynamic> content) =>
      store.add(LeakSummary.fromJson(content));

  void checkAndClear(LeakSummary summary) {
    expect(store, hasLength(1));
    expect(store.first.toJson(), summary.toJson());
    store.clear();
  }
}

class _MockLeakProvider implements LeakProvider {
  LeakSummary value = const LeakSummary({});

  @override
  LeakSummary leaksSummary() => value;
}
