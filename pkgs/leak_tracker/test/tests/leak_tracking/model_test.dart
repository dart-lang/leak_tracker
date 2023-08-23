// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:leak_tracker/src/leak_tracking/_primitives/model.dart';
import 'package:leak_tracker/src/shared/shared_model.dart';
import 'package:test/test.dart';

void main() {
  test('$Leaks serializes.', () {
    final leaks = Leaks({
      LeakType.gcedLate: [
        LeakReport(
          trackedClass: 'trackedClass1',
          type: 't1',
          context: {'a': 1, 'b': 3.14, 'c': ''},
          code: 1,
          phase: null,
        ),
      ],
      LeakType.notDisposed: [
        LeakReport(
          trackedClass: 'trackedClass2',
          type: 't2',
          context: {},
          code: 2,
          phase: null,
        ),
      ],
      LeakType.notGCed: [
        LeakReport(
          trackedClass: 'trackedClass3',
          type: 't3',
          context: {},
          code: 1,
          phase: null,
        ),
      ],
    });

    final json = leaks.toJson();

    expect(
      jsonEncode(json),
      jsonEncode(Leaks.fromJson(json).toJson()),
    );
  });

  test('$LeakSummary serializes.', () {
    final leakSummary = LeakSummary(
      {
        LeakType.gcedLate: 2,
        LeakType.notDisposed: 3,
        LeakType.notGCed: 4,
      },
      time: DateTime(2022),
    );

    final json = leakSummary.toJson();

    expect(
      jsonEncode(json),
      jsonEncode(LeakSummary.fromJson(json).toJson()),
    );
  });

  test('$PhaseSettings equality', () {
    const phase1 = PhaseSettings();

    const phase2 = PhaseSettings(
      leakDiagnosticConfig: LeakDiagnosticConfig(
        collectStackTraceOnDisposal: true,
        collectStackTraceOnStart: true,
      ),
    );

    expect(phase1 == phase2, false);
  });

  group('$ValueSampler', () {
    test('equality', () {
      final sampler1 = ValueSampler.start(initialValue: 1);
      sampler1.add(2);
      sampler1.add(3);

      final sampler2 = ValueSampler.start(initialValue: 1);
      sampler2.add(3);
      sampler2.add(2);

      expect(sampler1 == sampler2, true);
    });

    test('math', () {
      final sampler = ValueSampler.start(initialValue: 1);

      expect(sampler.samples, 1);
      expect(sampler.absAvg, 1);
      expect(sampler.absMax, 1);
      expect(sampler.deltaAvg, 0);
      expect(sampler.deltaMax, 0);

      sampler.add(2);

      expect(sampler.samples, 2);
      expect(sampler.absAvg, 1.5);
      expect(sampler.absMax, 2);
      expect(sampler.deltaAvg, 0.5);
      expect(sampler.deltaMax, 1);
    });
  });
}
