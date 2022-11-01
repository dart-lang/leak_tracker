// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_analysis.dart';
import 'package:test/test.dart';

void main() {
  test('$Leaks serializes.', () {
    // final task = NotGCedAnalyzerTask(
    //   reports: [
    //     LeakReport(
    //       type: 'type',
    //       details: ['details'],
    //       code: 2,
    //     )
    //   ],
    //   heap: AdaptedHeapData(
    //     [
    //       AdaptedHeapObject(
    //         heapClass: HeapClassName(
    //           className: 'class',
    //           library: 'library',
    //         ),
    //         references: [2, 3, 4],
    //         code: 6,
    //         shallowSize: 1,
    //       ),
    //     ],
    //     rootIndex: 0,
    //   ),
    // );

    // final json = task.toJson();

    // expect(
    //   jsonEncode(json),
    //   jsonEncode(NotGCedAnalyzerTask.fromJson(json).toJson()),
    // );
  });

  test('$LeakSummary serializes.', () {
    // final task = NotGCedAnalyzerTask(
    //   reports: [
    //     LeakReport(
    //       type: 'type',
    //       details: ['details'],
    //       code: 2,
    //     )
    //   ],
    //   heap: AdaptedHeapData(
    //     [
    //       AdaptedHeapObject(
    //         heapClass: HeapClassName(
    //           className: 'class',
    //           library: 'library',
    //         ),
    //         references: [2, 3, 4],
    //         code: 6,
    //         shallowSize: 1,
    //       ),
    //     ],
    //     rootIndex: 0,
    //   ),
    // );

    // final json = task.toJson();

    // expect(
    //   jsonEncode(json),
    //   jsonEncode(NotGCedAnalyzerTask.fromJson(json).toJson()),
    // );
  });
}
