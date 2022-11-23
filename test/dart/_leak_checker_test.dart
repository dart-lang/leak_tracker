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

void main() {
  late _MockStdoutSink stdout;
  late _MockDevToolsSink devtools;
  late _MockLeakProvider leakProvider;
  late List<LeakSummary> listened;
  const period = Duration(milliseconds: 5);

  LeakChecker leakChecker({
    bool checkPeriodically = true,
    bool hasListener = false,
    bool hasStdout = true,
    bool hasDevtools = true,
  }) =>
      LeakChecker(
        leakProvider: leakProvider,
        checkPeriod: checkPeriodically ? period : null,
        leakListener: hasListener ? (summary) => listened.add(summary) : null,
        stdoutLeaks: hasStdout,
        notifyDevTools: hasDevtools,
        stdoutSink: stdout,
        devToolsSink: devtools,
      );

  setUp(() {
    stdout = _MockStdoutSink();
    devtools = _MockDevToolsSink();
    leakProvider = _MockLeakProvider();
    listened = <LeakSummary>[];
  });

  test('Mocked checker has the same defaults as real config.', () {
    final config = LeakTrackingConfiguration();
    final checker = leakChecker();

    expect(config.notifyDevTools, checker.notifyDevTools);
    expect(config.stdoutLeaks, checker.stdoutLeaks);
    expect(config.checkPeriod == null, checker.checkPeriod == null);
  });
}

class _MockStdoutSink implements StdoutSink {
  final sink = <String>[];

  @override
  void print(String content) => sink.add(content);
}

class _MockDevToolsSink implements DevToolsSink {
  final sink = <Map<String, dynamic>>[];

  @override
  void send(Map<String, dynamic> content) => sink.add(content);
}

class _MockLeakProvider implements LeakProvider {
  LeakSummary value = LeakSummary({});

  @override
  LeakSummary leaksSummary() => value;
}
