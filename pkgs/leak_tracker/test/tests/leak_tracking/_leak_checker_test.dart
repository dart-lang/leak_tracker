// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_leak_reporter.dart';
import 'package:test/test.dart';

class _SummaryValues {
  static final zero = LeakSummary({});

  static final nonZero = LeakSummary({
    LeakType.gcedLate: 1,
    LeakType.notDisposed: 2,
    LeakType.notGCed: 3,
  });

  static final nonZeroCopy =
      LeakSummary(<LeakType, int>{}..addAll(nonZero.totals));
}

void main() {
  late _MockLeakProvider leakProvider;

  late _MockStdoutSink stdout;
  late _ListenedSink listened;

  const period = Duration(milliseconds: 5);
  late final doublePeriod = Duration(microseconds: period.inMicroseconds);

  LeakReporter leakChecker({
    required bool checkPeriodically,
    required bool hasListener,
    required bool hasStdout,
  }) =>
      LeakReporter(
        leakProvider: leakProvider,
        checkPeriod: checkPeriodically ? period : null,
        onLeaks: hasListener ? (summary) => listened.store.add(summary) : null,
        stdoutSink: hasStdout ? stdout : null,
      );

  LeakReporter defaultLeakChecker() => leakChecker(
        checkPeriodically: true,
        hasListener: false,
        hasStdout: true,
      );

  setUp(() {
    leakProvider = _MockLeakProvider();

    stdout = _MockStdoutSink();
    listened = _ListenedSink();
  });

  test('Mocks emulate production well.', () {
    expect(
      _SummaryValues.zero.toMessage(),
      isNot(_SummaryValues.nonZero.toMessage()),
    );
    expect(
      _SummaryValues.nonZero.toMessage(),
      _SummaryValues.nonZeroCopy.toMessage(),
    );

    // Mock defaults match real configuration defaults.
    const config = LeakTrackingConfig();
    final checker = defaultLeakChecker();
    expect(config.stdoutLeaks, checker.stdoutSink != null);
    expect(config.onLeaks == null, checker.onLeaks == null);
    expect(config.checkPeriod == null, checker.checkPeriod == null);
  });

  test('Default checker sends leaks to stdout.', () async {
    // ignore: unused_local_variable
    final checker = defaultLeakChecker();

    // Make sure there is no leaks.
    expect(stdout.store, isEmpty);

    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);

    // Report leaks and make sure they signaled one time.
    leakProvider.value = _SummaryValues.nonZero;
    await Future<void>.delayed(doublePeriod);
    stdout.checkStoreAndClear([_SummaryValues.nonZero]);

    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);

    // Report the same leak totals and make sure there is no signals.
    leakProvider.value = _SummaryValues.nonZeroCopy;
    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);

    // Drop totals and check signal.
    leakProvider.value = _SummaryValues.zero;
    await Future<void>.delayed(doublePeriod);
    stdout.checkStoreAndClear([_SummaryValues.zero]);

    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
  });

  test('Listener-only checker sends leaks to just listener.', () async {
    // ignore: unused_local_variable
    final checker = leakChecker(
      hasStdout: false,
      hasListener: true,
      checkPeriodically: true,
    );

    // Make sure there is no leaks.
    expect(stdout.store, isEmpty);
    expect(listened.store, isEmpty);

    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(listened.store, isEmpty);

    // Report leaks and make sure they signaled one time.
    leakProvider.value = _SummaryValues.nonZero;
    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    listened.checkStoreAndClear([_SummaryValues.nonZero]);

    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(listened.store, isEmpty);

    // Report the same leak totals and make sure there is no signals.
    leakProvider.value = _SummaryValues.nonZeroCopy;
    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(listened.store, isEmpty);

    // Drop totals and check signal.
    leakProvider.value = _SummaryValues.zero;
    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    listened.checkStoreAndClear([_SummaryValues.zero]);

    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(listened.store, isEmpty);
  });

  test('No-timer checker sends leaks when checked.', () async {
    // ignore: unused_local_variable
    final checker = leakChecker(
      checkPeriodically: false,
      hasStdout: true,
      hasListener: true,
    );

    // Make sure there is no leaks.
    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(listened.store, isEmpty);

    // Report leaks and make sure did not signal.
    leakProvider.value = _SummaryValues.nonZero;
    await Future<void>.delayed(doublePeriod);
    expect(stdout.store, isEmpty);
    expect(listened.store, isEmpty);

    // Check leaks and make sure they signaled one time.
    await checker.checkLeaks();
    stdout.checkStoreAndClear([_SummaryValues.nonZero]);
    listened.checkStoreAndClear([_SummaryValues.nonZero]);
  });
}

class _ListenedSink {
  final store = <LeakSummary>[];

  void checkStoreAndClear(List<LeakSummary> items) {
    expect(store, hasLength(items.length));
    for (final i in Iterable<int>.generate(store.length)) {
      expect(store[i].toMessage(), contains(items[i].toMessage()));
    }
    store.clear();
  }
}

class _MockStdoutSink implements StdoutSummarySink {
  final store = <LeakSummary>[];

  @override
  void send(LeakSummary summary) => store.add(summary);

  void checkStoreAndClear(List<LeakSummary> items) {
    expect(store, hasLength(items.length));
    for (final i in Iterable<int>.generate(store.length)) {
      expect(store[i].toMessage(), contains(items[i].toMessage()));
    }
    store.clear();
  }
}

class _MockLeakProvider implements LeakProvider {
  LeakSummary value = LeakSummary({});

  @override
  Future<LeakSummary> leaksSummary() async => value;

  @override
  Future<Leaks> collectLeaks() async => throw UnimplementedError();

  @override
  Future<void> checkNotGCed() => throw UnimplementedError();
}
