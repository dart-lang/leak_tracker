// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:developer';

import 'package:test/test.dart';

Future<WeakReference<Object>> _createTrackedObject(
  Finalizer<Object> finalizer,
) async {
  final theObject = Iterable.generate(1000, (_) => DateTime.now());

  // Delay to increase chances for the object to get to old gc space.
  await Future<void>.delayed(const Duration(milliseconds: 10));

  finalizer.attach(theObject, identityHashCode(theObject));
  return WeakReference(theObject);
}

late List<List<DateTime>> _storage;

void _allocateMemory() {
  _storage.add(Iterable.generate(10000, (_) => DateTime.now()).toList());
}

/// Tests for non-guaranteed assumptions about Dart garbage collector,
/// the leak_tracker relies on.
void main() {
  setUp(() => _storage = []);

  tearDown(() => _storage.clear());

  test('Non-referenced object is finalized and gced after barrier increase.',
      () async {
    var finalized = false;
    final finalizer = Finalizer<Object>((token) => finalized = true);
    final ref = await _createTrackedObject(finalizer);
    final barrier = reachabilityBarrier;

    while (reachabilityBarrier <= barrier + 2) {
      _allocateMemory();
      // Delay to give space to garbage collector.
      await Future<void>.delayed(const Duration());
    }

    expect(finalized, true);
    expect(ref.target, isNull);
  });
}
