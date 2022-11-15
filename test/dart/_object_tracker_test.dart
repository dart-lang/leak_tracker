// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/_gc_counter.dart';
import 'package:leak_tracker/src/_object_tracker.dart';
import 'package:leak_tracker/src/_primitives.dart';
import 'package:leak_tracker/src/leak_tracker_model.dart';
import 'package:test/test.dart';

void main() {
  final config = LeakTrackingConfiguration();
  late _MockFinalizerBuilder finalizerBuilder;
  late _MockGcCounter gcCounter;
  late ObjectTracker tracker;

  setUp(() {
    finalizerBuilder = _MockFinalizerBuilder();
    gcCounter = _MockGcCounter();
    tracker = ObjectTracker(
      config,
      finalizerBuilder: finalizerBuilder.build,
      gcCounter: gcCounter,
    );
  });

  test('$ObjectTracker uses finalizer.', () {
    const theObject = '-';
    tracker.startTracking(theObject, null);
    expect(
      finalizerBuilder.finalizer.attached,
      contains(identityHashCode(theObject)),
    );
  });

  test('$ObjectTracker tracks non disposed.', () {
    const theObject = '-';
    tracker.startTracking(theObject, null);
    finalizerBuilder.finalizer.finalize(identityHashCode(theObject));
  });
}

class _MockFinalizer implements Finalizer<Object> {
  _MockFinalizer(this.onGc);

  final ObjectGcCallback onGc;
  final attached = <Object>{};

  @override
  void attach(Object value, Object finalizationToken, {Object? detach}) {
    if (attached.contains(value)) throw '`attach` should not be invoked twice';
    attached.add(value);
  }

  @override
  void detach(Object detach) {}

  void finalize(Object code) => onGc(code);
}

class _MockFinalizerBuilder {
  late final _MockFinalizer finalizer;

  _MockFinalizer build(ObjectGcCallback onGc) {
    return finalizer = _MockFinalizer(onGc);
  }
}

class _MockGcCounter implements GcCounter {
  @override
  int gcCount = 0;
}
