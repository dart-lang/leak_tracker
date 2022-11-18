// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';
import 'package:leak_tracker/leak_analysis.dart';
import 'package:leak_tracker/src/_gc_counter.dart';
import 'package:leak_tracker/src/_object_tracker.dart';
import 'package:leak_tracker/src/_primitives.dart';
import 'package:test/test.dart';

void main() {
  late _MockFinalizerBuilder finalizerBuilder;
  late _MockGcCounter gcCounter;
  late ObjectTracker tracker;

  void _verifyOneLeakIsRegistered(
    Object object,
    LeakType type,
    String trackedClass,
  ) {
    final summary = tracker.collectLeaksSummary();
    final leaks = tracker.collectLeaks();

    expect(summary.total, 1);
    expect(summary.totals[type], 1);

    expect(leaks.total, 1);
    final theLeak = leaks.byType[type]!.single;
    expect(theLeak.type, object.runtimeType.toString());
    expect(theLeak.code, identityHashCode(object));
    expect(theLeak.trackedClass, trackedClass);
  }

  void _verifyNoLeaks() {
    final summary = tracker.collectLeaksSummary();
    final leaks = tracker.collectLeaks();

    expect(summary.total, 0);
    expect(leaks.total, 0);
  }

  /// Emulates GC.
  void _gc(Object object) {
    finalizerBuilder.finalizer.finalize(identityHashCode(object));
  }

  group('$ObjectTracker default', () {
    setUp(() {
      finalizerBuilder = _MockFinalizerBuilder();
      gcCounter = _MockGcCounter();
      tracker = ObjectTracker(
        finalizerBuilder: finalizerBuilder.build,
        gcCounter: gcCounter,
      );
    });

    test('uses finalizer.', () {
      const theObject = '-';
      tracker.startTracking(theObject, context: null, trackedClass: '');
      expect(
        finalizerBuilder.finalizer.attached,
        contains(theObject),
      );
    });

    test('does not false positive.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(theObject, context: null, trackedClass: '');
      });

      // Time travel.
      time = time.add(disposalTimeBuffer * 1000);
      gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer * 1000;

      // Verify no leaks.
      withClock(Clock.fixed(time), () {
        _verifyNoLeaks();
      });
    });

    test('tracks ${LeakType.notDisposed}.', () {
      // Define object.
      const theObject = '-';

      // Start tracking and GC.
      tracker.startTracking(
        theObject,
        context: null,
        trackedClass: 'trackedClass',
      );
      _gc(theObject);

      // Verify not-disposal is registered.
      _verifyOneLeakIsRegistered(
        theObject,
        LeakType.notDisposed,
        'trackedClass',
      );
    });

    test('tracks ${LeakType.notGCed}.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: 'trackedClass',
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(disposalTimeBuffer);
      gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer;

      // Verify leak is registered.
      withClock(Clock.fixed(time), () {
        _verifyOneLeakIsRegistered(theObject, LeakType.notGCed, 'trackedClass');
      });
    });

    test('tracks ${LeakType.gcedLate}.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: 'trackedClass',
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(disposalTimeBuffer);
      gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer;

      // GC and verify leak is registered.
      withClock(Clock.fixed(time), () {
        _gc(theObject);
        _verifyOneLeakIsRegistered(
          theObject,
          LeakType.gcedLate,
          'trackedClass',
        );
      });
    });
  });

  group('$ObjectTracker with callstacks', () {
    setUp(() {
      finalizerBuilder = _MockFinalizerBuilder();
      gcCounter = _MockGcCounter();
      tracker = ObjectTracker(
        finalizerBuilder: finalizerBuilder.build,
        gcCounter: gcCounter,
        classesToCollectStackTraceOnStart: {'String'},
        classesToCollectStackTraceOnDisposal: {'String'},
      );
    });

    test('collects callstacks.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: 'trackedClass',
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(disposalTimeBuffer);
      gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer;

      // GC and verify leak contains callstacks.
      withClock(Clock.fixed(time), () {
        _gc(theObject);
        final theLeak =
            tracker.collectLeaks().byType[LeakType.gcedLate]!.single;

        expect(theLeak.context, hasLength(2));
        final start = theLeak.context!['start'].toString();
        final disposal = theLeak.context!['disposal'].toString();

        const libName = '_object_tracker_test.dart';
        expect(start, contains(libName));
        expect(disposal, contains(libName));
        expect(start, isNot(equals(disposal)));
      });
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
