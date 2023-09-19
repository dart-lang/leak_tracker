// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

class _TrackedClass {
  _TrackedClass() {
    MemoryAllocations.instance.dispatchObjectCreated(
      library: 'library',
      className: '_TrackedClass',
      object: this,
    );
  }

  void dispose() {
    MemoryAllocations.instance.dispatchObjectDisposed(object: this);
  }
}

void main() {
  test('dispatchesMemoryEvents success sync', () async {
    await expectLater(
      await memoryEvents(() => _TrackedClass().dispose(), _TrackedClass),
      areCreateAndDispose,
    );
  });

  test('dispatchesMemoryEvents failure sync', () async {
    try {
      await expectLater(
        await memoryEvents(() {}, _TrackedClass),
        areCreateAndDispose,
      );
    } catch (e) {
      expect(e, isA<TestFailure>());
    }
  });

  test('dispatchesMemoryEvents success async', () async {
    await expectLater(
      await memoryEvents(() async => _TrackedClass().dispose(), _TrackedClass),
      areCreateAndDispose,
    );
  });

  test('dispatchesMemoryEvents failure async', () async {
    try {
      await expectLater(
        await memoryEvents(() async {}, _TrackedClass),
        areCreateAndDispose,
      );
    } catch (e) {
      expect(e, isA<TestFailure>());
    }
  });
}
