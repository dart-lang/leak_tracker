// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:clock/clock.dart';

import '../shared/shared_model.dart';
import '_formatting.dart';
import '_gc_counter.dart';
import 'leak_tracker.dart';
import 'leak_tracker_model.dart';
import 'retaining_path/_retaining_path.dart';

/// Asynchronous callback.
///
/// The prefix `Dart` is used to avoid conflict with Flutter's [AsyncCallback].
typedef DartAsyncCallback = Future<void> Function();

typedef AsyncCodeRunner = Future<void> Function(DartAsyncCallback);

class MemoryLeaksDetectedError extends StateError {
  MemoryLeaksDetectedError(this.leaks) : super('Leaks detected.');
  final Leaks leaks;
}

/// Runs [callback] with memory leak detection.
///
/// See https://github.com/dart-lang/leak_tracker
/// for memory leak definition.
///
/// If leaks are not detected, returns empty collection of leaks.
///
/// If leaks are detected, either returns collection of leaks
/// or throws [MemoryLeaksDetectedError], depending on value of [shouldThrowOnLeaks].
///
/// Flip [shouldThrowOnLeaks] to false if you want to test cover the leak tracker or
/// analyze leak details in the returned result.
///
/// Pass [timeoutForFinalGarbageCollection] if you do not want leak tracker
/// to wait infinitely for the forced garbage collection, that is needed
/// to analyse results.
///
/// If you test Flutter widgets, connect their instrumentation to the leak
/// tracker:
/// ```
/// void flutterEventListener(ObjectEvent event) => dispatchObjectEvent(event.toMap());
///
/// setUpAll(() {
///   MemoryAllocations.instance.addListener(flutterEventListener);
/// });
///
/// tearDownAll(() {
///   MemoryAllocations.instance.removeListener(flutterEventListener);
/// });
/// ```
///
/// If you use [withLeakTracking] inside `testWidget`, pass `tester.runAsync`
/// as [asyncCodeRunner] to run asynchronous leak detection after the
/// test code execution:
///
/// ```
/// testWidgets('...', (WidgetTester tester) async {
///   await withLeakTracking(
///     () async {
///       ...
///     },
///     asyncCodeRunner: (action) async => tester.runAsync(action),
///   );
/// });
/// ```
Future<Leaks> withLeakTracking(
  DartAsyncCallback? callback, {
  bool shouldThrowOnLeaks = true,
  Duration? timeoutForFinalGarbageCollection,
  LeakDiagnosticConfig leakDiagnosticConfig = const LeakDiagnosticConfig(),
  AsyncCodeRunner? asyncCodeRunner,
}) async {
  if (callback == null) return Leaks({});

  enableLeakTracking(
    resetIfAlreadyEnabled: true,
    config: LeakTrackingConfiguration.passive(
      leakDiagnosticConfig: leakDiagnosticConfig,
    ),
  );

  try {
    await callback();
    callback = null;

    asyncCodeRunner ??= (action) async => await action();
    Leaks? leaks;

    await asyncCodeRunner(
      () async {
        if (leakDiagnosticConfig.collectRetainingPathForNonGCed) {
          // This early check is needed to collect retaing pathes before forced GC,
          // because pathes are unavailable for GCed objects.
          await checkNonGCed();
        }

        await forceGC(
          fullGcCycles: gcCountBuffer,
          timeout: timeoutForFinalGarbageCollection,
        );

        leaks = await collectLeaks();

        if ((leaks?.total ?? 0) > 0 && shouldThrowOnLeaks) {
          // `expect` should not be used here, because, when the method is used
          // from Flutter, the packages `test` and `flutter_test` conflict.
          throw MemoryLeaksDetectedError(leaks!);
        }
      },
    );

    // `tester.runAsync` does not throw in case of errors, but collect them other way.
    if (leaks == null) throw StateError('Leaks collection failed.');
    return leaks!;
  } finally {
    disableLeakTracking();
  }
}

/// Forces garbage collection by aggressive memory allocation.
///
/// Verifies that garbage collection happened using [reachabilityBarrier].
/// Does not work in web and in release mode.
///
/// Use [timeout] to limit waitning time.
/// Use [fullGcCycles] to force multiple garbage collections.
///
/// The methot is useable for testing in combination with [WeakReference] to ensure
/// an object is not held by another object from garbage collection.
///
/// For code example see
/// https://github.com/dart-lang/leak_tracker/blob/main/doc/TROUBLESHOOT.md
Future<void> forceGC({
  Duration? timeout,
  int fullGcCycles = 1,
}) async {
  final Stopwatch? stopwatch = timeout == null ? null : (Stopwatch()..start());
  final int barrier = reachabilityBarrier;

  final List<List<DateTime>> storage = <List<DateTime>>[];

  void allocateMemory() {
    storage.add(
      Iterable<DateTime>.generate(10000, (_) => DateTime.now()).toList(),
    );
    if (storage.length > 100) {
      storage.removeAt(0);
    }
  }

  while (reachabilityBarrier < barrier + fullGcCycles) {
    if ((stopwatch?.elapsed ?? Duration.zero) > (timeout ?? Duration.zero)) {
      throw TimeoutException('forceGC timed out', timeout);
    }
    await Future<void>.delayed(Duration.zero);
    allocateMemory();
  }
}

/// Returns nicely formatted retaining path for the [ref.target].
///
/// If the object is garbage collected or not retained, returns null.
///
/// Does not work in web and in release mode.
Future<String?> formattedRetainingPath(WeakReference ref) async {
  if (ref.target == null) return null;
  final path = await obtainRetainingPath(
    ref.target.runtimeType,
    identityHashCode(ref.target),
  );

  if (path == null) return null;
  return retainingPathToString(path);
}
