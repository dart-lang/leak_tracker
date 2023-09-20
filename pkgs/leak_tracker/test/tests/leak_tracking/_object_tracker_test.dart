// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_object_record.dart';
import 'package:leak_tracker/src/leak_tracking/_object_tracker.dart';
import 'package:leak_tracker/src/leak_tracking/_primitives/_finalizer.dart';
import 'package:leak_tracker/src/leak_tracking/_primitives/_gc_counter.dart';
import 'package:leak_tracker/src/shared/_util.dart';
import 'package:test/test.dart';

import '../../test_infra/data/dart_classes.dart';

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

    setUp(() {
      tracker = ObjectTracker(
        disposalTime: _disposalTime,
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
      const theObject = [];
      tracker.startTracking(
        theObject,
        context: null,
        trackedClass: '',
        phase: const PhaseSettings(),
      );
      expect(
        finalizerBuilder.finalizer.attached.values,
        contains(theObject),
      );
    });

    test('does not false positive.', () {
      // Define object and time.
      const theObject = [];
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
      const theObject = [];

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
      const theObject = [];
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
      const theObject = [];
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
      const theObject = [];
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
      const theObject = [];
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
      const theObject = [];
      var time = DateTime(2000);

      // Start tracking and dispose.
      withClock(Clock.fixed(time), () {
        tracker.startTracking(
          theObject,
          context: null,
          trackedClass: _trackedClass,
          phase: const PhaseSettings(
            leakDiagnosticConfig: LeakDiagnosticConfig(
              collectStackTraceOnStart: true,
              collectStackTraceOnDisposal: true,
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

  group('$ObjectTracker respects phase settings,', () {
    late _MockFinalizerBuilder finalizerBuilder;
    late _MockGcCounter gcCounter;
    late ObjectTracker tracker;

    final objectsToPhases = <Object, PhaseSettings>{
      Named('0'): const PhaseSettings.paused(),
      Named('1'): const PhaseSettings(
        name: '1',
      ),
      Named('2'): const PhaseSettings.paused(),
      Named('3'): const PhaseSettings(
        name: '3',
      ),
      Named('4'): const PhaseSettings(
        name: '4',
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectRetainingPathForNotGCed: true,
        ),
      ),
      Named('5'): const PhaseSettings(
        name: '5',
        leakDiagnosticConfig: LeakDiagnosticConfig(
          collectStackTraceOnDisposal: true,
        ),
      ),
      Named('6'): const PhaseSettings(
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
        phase: phase,
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

    void checkContext(
      Map<String, dynamic>? context, {
      required bool shouldContain,
      required String key,
    }) {
      if (shouldContain) {
        expect(context!.keys, contains(key));
      } else {
        expect(context?.keys ?? [], isNot(contains(key)));
      }
    }

    void checkNotDisposedLeak(
      Leaks leaks,
      PhaseSettings phase, {
      required Object object,
    }) {
      var leak = leaks.notDisposed
          .where((l) => l.code == identityHashCode(object))
          .onlyOrNull;

      if (phase.isLeakTrackingPaused || phase.allowAllNotDisposed) {
        expect(leak, isNull);
        return;
      }
      leak = leak!;

      expect(leak.phase, phase.name);

      checkContext(
        leak.context,
        shouldContain: phase.leakDiagnosticConfig.collectStackTraceOnStart,
        key: ContextKeys.startCallstack,
      );
    }

    void checkNotGCedLeak(
      Leaks leaks,
      PhaseSettings phase, {
      required Object object,
    }) {
      var leak = leaks.notGCed
          .where((l) => l.code == identityHashCode(object))
          .onlyOrNull;

      if (phase.isLeakTrackingPaused || phase.allowAllNotGCed) {
        expect(leak, isNull);
        return;
      }
      leak = leak!;

      expect(leak.phase, phase.name);

      checkContext(
        leak.context,
        shouldContain: phase.leakDiagnosticConfig.collectStackTraceOnStart,
        key: ContextKeys.startCallstack,
      );
      checkContext(
        leak.context,
        shouldContain: phase.leakDiagnosticConfig.collectStackTraceOnDisposal,
        key: ContextKeys.disposalCallstack,
      );
      checkContext(
        leak.context,
        shouldContain:
            phase.leakDiagnosticConfig.collectRetainingPathForNotGCed,
        key: ContextKeys.retainingPath,
      );
    }

    for (var gced in [
      true,
      false,
    ]) {
      for (var disposed in [
        true,
        false,
      ]) {
        test(
            'when objects are tracked with different settings, disposed=$disposed, gced=$gced.',
            () async {
          var time = DateTime(2000);

          // Start tracking.
          withClock(Clock.fixed(time), () {
            for (var object in objectsToPhases.keys) {
              final phase = objectsToPhases[object]!;
              // Start tracking.
              startTracking(object, phase);
            }

            for (var object in objectsToPhases.keys) {
              // Dispose and garbage collect.
              if (disposed) tracker.dispatchDisposal(object, context: null);
              if (gced) finalizerBuilder.gc(object);
            }

            // Emulate garbage collection.
            gcCounter.gcCount = gcCounter.gcCount + defaultNumberOfGcCycles;
          });

          // Time travel
          time = time.add(_disposalTime);
          await withClock(Clock.fixed(time), () async {
            // Collect leaks.
            final leaks = await tracker.collectLeaks();

            // Verify leaks.
            final expectedNotGCed = objectsToPhases.keys
                .where(
                  (o) =>
                      !objectsToPhases[o]!.isLeakTrackingPaused &&
                      !objectsToPhases[o]!.allowAllNotGCed &&
                      !gced &&
                      disposed,
                )
                .length;
            final expectedNotDisposed = objectsToPhases.keys
                .where(
                  (o) =>
                      !objectsToPhases[o]!.isLeakTrackingPaused &&
                      !objectsToPhases[o]!.allowAllNotDisposed &&
                      !disposed &&
                      gced,
                )
                .length;

            expect(leaks.total, expectedNotDisposed + expectedNotGCed);
            expect(leaks.notGCed.length, expectedNotGCed);
            expect(leaks.notDisposed.length, expectedNotDisposed);

            if (leaks.total == 0) return;

            for (var object in objectsToPhases.keys) {
              final phase = objectsToPhases[object]!;
              if (gced && !disposed) {
                checkNotDisposedLeak(leaks, phase, object: object);
              }
              if (disposed && !gced) {
                checkNotGCedLeak(leaks, phase, object: object);
              }
            }
          });
        });
      }
    }
  });
}

class _MockFinalizerWrapper implements FinalizerWrapper {
  _MockFinalizerWrapper(this.onGc);

  final ObjectGcCallback onGc;
  // Maps tokens to objects.
  final attached = <ObjectRecord, Object>{};

  @override
  void attach(Object object, Object finalizationToken, {Object? detach}) {
    if (attached.containsValue(object)) {
      throw '`attach` should not be invoked twice';
    }
    if (attached.containsKey(finalizationToken)) {
      throw 'tokens should not duplicate';
    }
    attached[finalizationToken as ObjectRecord] = object;
  }

  void finalize(Object finalizationToken) {
    if (finalizationToken is! ObjectRecord) {
      throw 'Unexpected type of token: ${finalizationToken.runtimeType}';
    }
    if (!attached.containsKey(finalizationToken)) return;
    onGc(finalizationToken);
    attached.remove(finalizationToken);
  }
}

class _MockFinalizerBuilder {
  late final _MockFinalizerWrapper finalizer;

  void gc(Object object) {
    final token = finalizer.attached.entries
        .where((entry) => entry.value == object)
        .firstOrNull
        ?.key;
    if (token != null) finalizer.finalize(token);
  }

  _MockFinalizerWrapper build(ObjectGcCallback onGc) {
    return finalizer = _MockFinalizerWrapper(onGc);
  }
}

class _MockGcCounter implements GcCounter {
  @override
  int gcCount = 0;
}
