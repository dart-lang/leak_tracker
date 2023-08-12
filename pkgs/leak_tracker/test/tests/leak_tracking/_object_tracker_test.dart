// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_object_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_primitives/_finalizer.dart';
import 'package:leak_tracker/src/leak_tracking/_primitives/_gc_counter.dart';
import 'package:leak_tracker/src/shared/_primitives.dart';
import 'package:test/test.dart';

const String _trackedClass = 'trackedClass';
const _disposalTime = Duration(milliseconds: 100);

void main() {
  group('processIfNeeded', () {
    for (var items in [null, <int>[]]) {
      test('is noop for empty list, $items', () async {
        int processorCalls = 0;

        await ObjectTracker.processIfNeeded<int>(
          items: items,
          limit: 10,
          processor: (List<int> items) async {
            processorCalls++;
          },
        );

        expect(processorCalls, 0);
      });
    }

    for (var limit in [null, 100]) {
      test('processes all for no limit or large limit, $limit', () async {
        final itemsToProcess = [1, 2, 3];

        int processorCalls = 0;
        late final List<int> processedItems;

        await ObjectTracker.processIfNeeded<int>(
          items: itemsToProcess,
          limit: limit,
          processor: (List<int> items) async {
            processorCalls++;
            processedItems = items;
          },
        );

        expect(processorCalls, 1);
        expect(processedItems, itemsToProcess);
      });
    }

    test('cuts for limit', () async {
      final itemsToProcess = [1, 2, 3];

      int processorCalls = 0;
      late final List<int> processedItems;

      await ObjectTracker.processIfNeeded<int>(
        items: itemsToProcess,
        limit: 2,
        processor: (List<int> items) async {
          processorCalls++;
          processedItems = items;
        },
      );

      expect(processorCalls, 1);
      expect(processedItems, [1, 2]);
    });
  });

  group('$ObjectTracker handles duplicates', () {
    late ObjectTracker tracker;
    IdentityHashCode mockCoder(Object object) => 1;

    setUp(() {
      tracker = ObjectTracker(
        disposalTime: _disposalTime,
        coder: mockCoder,
        numberOfGcCycles: defaultNumberOfGcCycles,
        maxRequestsForRetainingPath: 0,
        switches: const Switches(),
      );
    });

    test('without failures.', () {
      final object1 = [1, 2, 3];
      final object2 = ['-'];

      tracker.startTracking(
        object1,
        context: null,
        trackedClass: _trackedClass,
        phase: const PhaseSettings(),
      );

      tracker.startTracking(
        object2,
        context: null,
        trackedClass: _trackedClass,
        phase: const PhaseSettings(),
      );
    });
  });

  group('$ObjectTracker default', () {
    late _MockFinalizerBuilder finalizerBuilder;
    late _MockGcCounter gcCounter;
    late ObjectTracker tracker;

    Future<void> verifyOneLeakIsRegistered(Object object, LeakType type) async {
      var summary = await tracker.leaksSummary();
      expect(summary.total, 1);

      // Second leak summary should be the same.
      summary = await tracker.leaksSummary();
      expect(summary.total, 1);
      expect(summary.totals[type], 1);

      var leaks = await tracker.collectLeaks();
      expect(leaks.total, 1);

      final theLeak = leaks.byType[type]!.single;
      expect(theLeak.type, object.runtimeType.toString());
      expect(theLeak.code, identityHashCode(object));
      expect(theLeak.trackedClass, _trackedClass);

      // Second leak collection should not return results.
      summary = await tracker.leaksSummary();
      leaks = await tracker.collectLeaks();
      expect(summary.total, 0);
      expect(leaks.total, 0);
    }

    void verifyNoLeaks() async {
      final summary = await tracker.leaksSummary();
      final leaks = await tracker.collectLeaks();

      expect(summary.total, 0);
      expect(leaks.total, 0);
    }

    setUp(() {
      finalizerBuilder = _MockFinalizerBuilder();
      gcCounter = _MockGcCounter();
      tracker = ObjectTracker(
        finalizerBuilder: finalizerBuilder.build,
        gcCounter: gcCounter,
        disposalTime: _disposalTime,
        numberOfGcCycles: defaultNumberOfGcCycles,
        maxRequestsForRetainingPath: 0,
        switches: const Switches(),
      );
    });

    test('uses finalizer.', () {
      const theObject = '-';
      tracker.startTracking(theObject,
          context: null, trackedClass: '', phase: const PhaseSettings());
      expect(
        finalizerBuilder.finalizer.attached,
        contains(identityHashCode(theObject)),
      );
    });

    test('does not false positive.', () {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: '',
          phase: const PhaseSettings(),
        );
      });

      // Time travel.
      time = time.add(_disposalTime * 1000);
      gcCounter.gcCount = gcCounter.gcCount + defaultNumberOfGcCycles * 1000;

      // Verify no leaks.
      withClock(Clock.fixed(time), () {
        verifyNoLeaks();
      });
    });

    test('tracks ${LeakType.notDisposed}.', () async {
      // Define object.
      const theObject = '-';

      // Start tracking and GC.
      tracker.startTracking(
        theObject,
        context: null,
        trackedClass: 'trackedClass',
        phase: const PhaseSettings(),
      );
      finalizerBuilder.gc(theObject);

      // Verify not-disposal is registered.
      await verifyOneLeakIsRegistered(theObject, LeakType.notDisposed);
    });

    test('tracks ${LeakType.notGCed}.', () async {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: 'trackedClass',
          phase: const PhaseSettings(),
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(_disposalTime);
      gcCounter.gcCount = gcCounter.gcCount + defaultNumberOfGcCycles;

      // Verify leak is registered.
      await withClock(Clock.fixed(time), () async {
        await verifyOneLeakIsRegistered(theObject, LeakType.notGCed);
      });
    });

    test('tracks ${LeakType.gcedLate}.', () async {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: 'trackedClass',
          phase: const PhaseSettings(),
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(_disposalTime);
      gcCounter.gcCount = gcCounter.gcCount + defaultNumberOfGcCycles;

      // GC and verify leak is registered.
      await withClock(Clock.fixed(time), () async {
        finalizerBuilder.gc(theObject);
        await verifyOneLeakIsRegistered(theObject, LeakType.gcedLate);
      });
    });

    test('tracks ${LeakType.gcedLate} lifecycle accurately.', () async {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: _trackedClass,
          phase: const PhaseSettings(),
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(_disposalTime);
      gcCounter.gcCount = gcCounter.gcCount + defaultNumberOfGcCycles;

      await withClock(Clock.fixed(time), () async {
        // Verify notGCed leak is registered.
        await verifyOneLeakIsRegistered(theObject, LeakType.notGCed);

        // GC and verify gcedLate leak is registered.
        finalizerBuilder.gc(theObject);
        await verifyOneLeakIsRegistered(theObject, LeakType.gcedLate);
      });
    });

    test('collects context accurately.', () async {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: {'0': 0},
          trackedClass: _trackedClass,
          phase: const PhaseSettings(),
        );
        tracker.addContext(theObject, context: {'1': 1});
        tracker.dispatchDisposal(theObject, context: {'2': 2});
      });

      // Time travel.
      time = time.add(_disposalTime);
      gcCounter.gcCount = gcCounter.gcCount + defaultNumberOfGcCycles;

      // Verify context for the collected nonGCed.
      await withClock(Clock.fixed(time), () async {
        final leaks = await tracker.collectLeaks();
        final context = leaks.notGCed.first.context!;
        for (final i in Iterable.generate(3)) {
          expect(context[i.toString()], i);
        }
      });
    });
  });

  group('$ObjectTracker with stack traces', () {
    late _MockFinalizerBuilder finalizerBuilder;
    late _MockGcCounter gcCounter;
    late ObjectTracker tracker;

    setUp(() {
      finalizerBuilder = _MockFinalizerBuilder();
      gcCounter = _MockGcCounter();
      tracker = ObjectTracker(
        finalizerBuilder: finalizerBuilder.build,
        gcCounter: gcCounter,
        disposalTime: _disposalTime,
        numberOfGcCycles: defaultNumberOfGcCycles,
        maxRequestsForRetainingPath: 0,
        switches: const Switches(),
      );
    });

    test('collects stack traces.', () async {
      // Define object and time.
      const theObject = '-';
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: _trackedClass,
          phase: const PhaseSettings(
            leakDiagnosticConfig: LeakDiagnosticConfig(
              classesToCollectStackTraceOnStart: {'String'},
              classesToCollectStackTraceOnDisposal: {'String'},
            ),
          ),
        );
        tracker.dispatchDisposal(theObject, context: null);
      });

      // Time travel.
      time = time.add(_disposalTime);
      gcCounter.gcCount = gcCounter.gcCount + defaultNumberOfGcCycles;

      // GC and verify leak contains callstacks.
      await withClock(Clock.fixed(time), () async {
        finalizerBuilder.gc(theObject);
        final theLeak =
            (await tracker.collectLeaks()).byType[LeakType.gcedLate]!.single;

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

  group('$ObjectTracker respects phases,', () {
    late _MockFinalizerBuilder finalizerBuilder;
    late _MockGcCounter gcCounter;
    late ObjectTracker tracker;

    const objectsToPhases = <Object, PhaseSettings>{
      '0': PhaseSettings.paused(),
      '1': PhaseSettings(
        name: '1',
      ),
      '2': PhaseSettings.paused(),
      '3': PhaseSettings(
        name: '3',
      ),
      '4': PhaseSettings(
        name: '4',
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectRetainingPathForNotGCed: true,
        ),
      ),
      '5': PhaseSettings(
        name: '5',
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectStackTraceOnDisposal: true,
        ),
      ),
      '6': PhaseSettings(
        name: '6',
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectStackTraceOnStart: true,
        ),
      ),
    };

    void startTracking(Object object, PhaseSettings phase) {
      tracker.startTracking(
        object,
        trackedClass: _trackedClass,
        context: null,
        phase: const PhaseSettings.paused(),
      );
    }

    setUp(() {
      finalizerBuilder = _MockFinalizerBuilder();
      gcCounter = _MockGcCounter();
      tracker = ObjectTracker(
        finalizerBuilder: finalizerBuilder.build,
        gcCounter: gcCounter,
        disposalTime: _disposalTime,
        numberOfGcCycles: defaultNumberOfGcCycles,
        maxRequestsForRetainingPath: null,
        switches: const Switches(),
      );
    });

    for (var gced in [true, false]) {
      for (var disposed in [true, false]) {
        test(
            'when objects are tracked with different settings, disposed=$disposed, gced=$gced.',
            () async {
          for (var object in objectsToPhases.keys) {
            // Start tracking.
            startTracking(object, objectsToPhases[object]!);
          }

          for (var object in objectsToPhases.keys) {
            // Dispose and garbage collect.
            if (disposed) tracker.dispatchDisposal(object, context: null);
            if (gced) finalizerBuilder.gc(object);
          }

          // Collect leaks.
          final leaks = await tracker.collectLeaks();
          final tracked = objectsToPhases.keys
              .where((o) => !objectsToPhases[o]!.isPaused)
              .length;
          expect(
            leaks.total,
            tracked * ((disposed ? 0 : 1) + (gced ? 0 : 1)),
          );
          expect(leaks.notGCed.length, tracked * (gced ? 0 : 1));
          expect(leaks.notDisposed.length, tracked * (gced ? 0 : 1));
        });
      }
    }

    test('when objects are tracked with different settings.', () async {});

    test('when object is with phase that tracks leaks.', () async {
      const objectBeforePhase = '1';
      const objectBeforePhaseLeaking = '2';
      const objectInPhase = '3';
      const objectInPhaseLeaking = '4';
      final allObjects = [
        objectBeforePhase,
        objectBeforePhaseLeaking,
        objectInPhase,
        objectInPhaseLeaking,
      ];

      // // Start tracking for all objects.
      // startTracking(objectBeforePhase);
      // startTracking(objectBeforePhaseLeaking);
      // startTracking(objectInPhase);
      // startTracking(objectInPhaseLeaking);

      // Dispose non-leaking objects.
      tracker.dispatchDisposal(objectInPhase, context: null);
      tracker.dispatchDisposal(objectBeforePhase, context: null);

      // GC all objects.
      allObjects.forEach(finalizerBuilder.gc);

      // Check leaks are collected only for leaking object that
      // was registered in the phase.
      final leaks = await tracker.collectLeaks();
      expect(leaks.total, 1);
      final theLeak = leaks.byType[LeakType.notDisposed]!.single;
      expect(theLeak.code, identityHashCode(objectInPhaseLeaking));
    });

    test('when object is with phase that does not track leaks.', () async {
      const objectDisposedInPhase = '1';
      const objectLeaking = '2';
      const objectDisposedAfterPhase = '3';
      final allObjects = [
        objectDisposedInPhase,
        objectLeaking,
        objectDisposedAfterPhase,
      ];

      // phase.value = const PhaseSettings(name: 'phase1');
      // allObjects.forEach(startTracking);
      // tracker.dispatchDisposal(objectDisposedInPhase, context: null);
      // phase.value = const PhaseSettings.paused();
      // tracker.dispatchDisposal(objectDisposedAfterPhase, context: null);

      // // GC all objects.
      // allObjects.forEach(finalizerBuilder.gc);

      // // Check leaks are collected only for leaking object that
      // // was registered in the phase.
      // final leaks = await tracker.collectLeaks();
      // expect(leaks.total, 1);
      // final theLeak = leaks.byType[LeakType.notDisposed]!.single;
      // expect(theLeak.code, identityHashCode(objectLeaking));
    });
  });
}

class _MockFinalizerWrapper implements FinalizerWrapper {
  _MockFinalizerWrapper(this.onGc);

  final ObjectGcCallback onGc;
  final attached = <Object>{};

  @override
  void attach(Object object, Object finalizationToken, {Object? detach}) {
    final int code = identityHashCode(object);
    if (attached.contains(code)) throw '`attach` should not be invoked twice';
    attached.add(code);
  }

  void finalize(Object code) {
    if (!attached.contains(code)) return;
    onGc(code);
    attached.remove(code);
  }
}

class _MockFinalizerBuilder {
  late final _MockFinalizerWrapper finalizer;

  void gc(Object object) {
    finalizer.finalize(identityHashCode(object));
  }

  _MockFinalizerWrapper build(ObjectGcCallback onGc) {
    return finalizer = _MockFinalizerWrapper(onGc);
  }
}

class _MockGcCounter implements GcCounter {
  @override
  int gcCount = 0;
}
