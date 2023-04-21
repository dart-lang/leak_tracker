// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_detection/_gc_counter.dart';
import 'package:leak_tracker/src/leak_detection/_object_tracker.dart';
import 'package:leak_tracker/src/shared/_primitives.dart';
import 'package:test/test.dart';

const String _trackedClass = 'trackedClass';

void main() {
  late _MockFinalizerBuilder finalizerBuilder;
  late _MockGcCounter gcCounter;
  late ObjectTracker tracker;
  const disposalTimeBuffer = Duration(milliseconds: 100);

  void verifyOneLeakIsRegistered(Object object, LeakType type) {
    var summary = tracker.leaksSummary();
    expect(summary.total, 1);

    // Second leak summary should be the same.
    summary = tracker.leaksSummary();
    expect(summary.total, 1);

    var leaks = tracker.collectLeaks();
    expect(summary.totals[type], 1);

    expect(leaks.total, 1);
    final theLeak = leaks.byType[type]!.single;
    expect(theLeak.type, object.runtimeType.toString());
    expect(theLeak.code, identityHashCode(object));
    expect(theLeak.trackedClass, _trackedClass);

    // Second leak collection should not return results.
    summary = tracker.leaksSummary();
    leaks = tracker.collectLeaks();
    expect(summary.total, 0);
    expect(leaks.total, 0);
  }

  void verifyNoLeaks() {
    final summary = tracker.leaksSummary();
    final leaks = tracker.collectLeaks();

    expect(summary.total, 0);
    expect(leaks.total, 0);
  }

  /// Emulates GC.
  void gc(Object object) {
    finalizerBuilder.finalizer.finalize(identityHashCode(object));
  }

  group('$ObjectTracker default', () {
    setUp(() {
      finalizerBuilder = _MockFinalizerBuilder();
      gcCounter = _MockGcCounter();
      tracker = ObjectTracker(
        stackTraceCollectionConfig: const StackTraceCollectionConfig(),
        finalizerBuilder: finalizerBuilder.build,
        gcCounter: gcCounter,
        disposalTimeBuffer: disposalTimeBuffer,
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
        verifyNoLeaks();
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
      gc(theObject);

      // Verify not-disposal is registered.
      verifyOneLeakIsRegistered(theObject, LeakType.notDisposed);
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
        verifyOneLeakIsRegistered(theObject, LeakType.notGCed);
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
        gc(theObject);
        verifyOneLeakIsRegistered(theObject, LeakType.gcedLate);
      });
    });

    test('tracks ${LeakType.gcedLate} lifecycle accurately.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: _trackedClass,
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(disposalTimeBuffer);
      gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer;

      withClock(Clock.fixed(time), () {
        // Verify notGCed leak is registered.
        verifyOneLeakIsRegistered(theObject, LeakType.notGCed);

        // GC and verify gcedLate leak is registered.
        gc(theObject);
        verifyOneLeakIsRegistered(theObject, LeakType.gcedLate);
      });
    });

    test('collects context accurately.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: {'0': 0},
          trackedClass: _trackedClass,
        );
        tracker.addContext(theObject, context: {'1': 1});
        tracker.dispatchDisposal(theObject, context: {'2': 2});
      });

      // Time travel.
      time = time.add(disposalTimeBuffer);
      gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer;

      // Verify context for the collected nonGCed.
      withClock(Clock.fixed(time), () {
        final leaks = tracker.collectLeaks();
        final context = leaks.notGCed.first.context!;
        for (final i in Iterable.generate(3)) {
          expect(context[i.toString()], i);
        }
      });
    });
  });

  group('$ObjectTracker with stack traces', () {
    setUp(() {
      finalizerBuilder = _MockFinalizerBuilder();
      gcCounter = _MockGcCounter();
      tracker = ObjectTracker(
        finalizerBuilder: finalizerBuilder.build,
        gcCounter: gcCounter,
        stackTraceCollectionConfig: const StackTraceCollectionConfig(
          classesToCollectStackTraceOnStart: {'String'},
          classesToCollectStackTraceOnDisposal: {'String'},
        ),
        disposalTimeBuffer: disposalTimeBuffer,
      );
    });

    test('collects stack traces.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: _trackedClass,
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(disposalTimeBuffer);
      gcCounter.gcCount = gcCounter.gcCount + gcCountBuffer;

      // GC and verify leak contains callstacks.
      withClock(Clock.fixed(time), () {
        gc(theObject);
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
