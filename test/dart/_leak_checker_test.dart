// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/_leak_checker.dart';
import 'package:leak_tracker/src/leak_analysis_model.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  test('-', () {});
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
