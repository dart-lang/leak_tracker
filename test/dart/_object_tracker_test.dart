// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';
import 'package:leak_tracker/leak_analysis.dart';
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

  void _verifyOneLeakIsRegistered(Object object, LeakType type) {
    final summary = tracker.collectLeaksSummary();
    final leaks = tracker.collectLeaks();

    expect(summary.total, 1);
    expect(summary.totals[type], 1);

    expect(leaks.total, 1);
    final theLeak = leaks.byType[type]!.first;
    expect(theLeak.type, object.runtimeType.toString());
    expect(theLeak.code, identityHashCode(object));
  }

  void _verifyNoLeaks() {
    final summary = tracker.collectLeaksSummary();
    final leaks = tracker.collectLeaks();

    expect(summary.total, 0);
    expect(leaks.total, 0);
  }

  test('$ObjectTracker uses finalizer.', () {
    const theObject = '-';
    tracker.startTracking(theObject, null);
    expect(
      finalizerBuilder.finalizer.attached,
      contains(theObject),
    );
  });

  test('$ObjectTracker does not false positive.', () {
    // Define object and time.
    const theObject = '-';
    var time = DateTime(2000);

    // Start tracking.
    withClock(Clock.fixed(time), () {
      tracker.startTracking(theObject, null);
    });

    // Time travel.
    time = time.add(disposalTimeBuffer * 1000);
    gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer * 1000;

    // Verify no leaks.
    withClock(Clock.fixed(time), () {
      _verifyNoLeaks();
    });
  });

  test('$ObjectTracker tracks ${LeakType.notDisposed}.', () {
    // Define object.
    const theObject = '-';
    final code = identityHashCode(theObject);

    // Start tracking and GC.
    tracker.startTracking(theObject, /* context  = */ null);
    finalizerBuilder.finalizer.finalize(code);

    // Verify not-disposal is registered.
    _verifyOneLeakIsRegistered(theObject, LeakType.notDisposed);
  });

  test('$ObjectTracker tracks ${LeakType.notGCed}.', () {
    // Define object and time.
    const theObject = '-';
    var time = DateTime(2000);

    // Start tracking and dispose.
    withClock(Clock.fixed(time), () {
      tracker.startTracking(theObject, /* context  = */ null);
      tracker.registerDisposal(theObject, /* context  = */ null);
    });

    // Time travel.
    time = time.add(disposalTimeBuffer);
    gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer;

    // Verify leak is registered.
    withClock(Clock.fixed(time), () {
      _verifyOneLeakIsRegistered(theObject, LeakType.notGCed);
    });
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
