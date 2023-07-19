// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import '../shared/shared_model.dart';
import '_formatting.dart';
import 'leak_tracker.dart';
import 'leak_tracker_model.dart';
import 'retaining_path/_connection.dart';
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
/// [gcCountBuffer] is delta of full GC cycles, enough for a non reachable object to be GCed.
///
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
  int gcCountBuffer = defaultGcCountBuffer,
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
          // This early check is needed to collect retaing paths before forced GC,
          // because paths are unavailable for GCed objects.
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
/// Use [timeout] to limit waiting time.
/// Use [fullGcCycles] to force multiple garbage collections.
///
/// The method is helpful for testing in combination with [WeakReference] to ensure
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

  final List<List<int>> storage = <List<int>>[];

  void allocateMemory() {
    storage.add(List.generate(30000, (n) => n));
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
///
/// Also does not work for objects that are not returned by getInstances.
/// https://github.com/dart-lang/sdk/blob/3e80d29fd6fec56187d651ce22ea81f1e8732214/runtime/vm/object_graph.cc#L1803
Future<String?> formattedRetainingPath(WeakReference ref) async {
  if (ref.target == null) return null;
  final connection = await connect();
  final path = await obtainRetainingPath(
    connection,
    ref.target.runtimeType,
    identityHashCode(ref.target),
  );
  disconnect();

  if (path == null) return null;
  return retainingPathToString(path);
}
