// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_primitives/_gc_counter.dart';
import '_primitives/model.dart';

/// Information about an object, tracked for leaks.
class ObjectRecord {
  ObjectRecord(
    Object object,
    this.context,
    this.trackedClass,
    this.phase,
  )   : ref = WeakReference(object),
        type = object.runtimeType,
        code = identityHashCode(object);

  final WeakReference<Object> ref;

  /// [IdentityHashCode] of the object.
  ///
  /// Is needed to help debugging notDisposed leak, for which
  /// the object is already GCed and thus there is no access to its code.
  final IdentityHashCode code;

  Map<String, dynamic>? context;

  final PhaseSettings phase;

  /// Runtime type of the tracked object.
  final Type type;

  final String trackedClass;

  DateTime? _disposalTime;
  int? _disposalGcCount;

  void setDisposed(int gcTime, DateTime time) {
    // TODO(polina-c): handle double disposal in a better way
    // https://github.com/dart-lang/leak_tracker/issues/118
    // Noop if object is already disposed.
    if (_disposalGcCount != null) return;
    if (_gcedGcCount != null) {
      throw 'The object $code should not be disposed after being GCed.';
    }
    _disposalGcCount = gcTime;
    _disposalTime = time;
  }

  DateTime? _gcedTime;
  int? _gcedGcCount;
  void setGCed(int gcCount, DateTime time) {
    if (_gcedGcCount != null) throw 'The object $code GCed twice.';
    _gcedGcCount = gcCount;
    _gcedTime = time;
  }

  bool get isGCed => _gcedGcCount != null;
  bool get isDisposed => _disposalGcCount != null;

  bool isGCedLateLeak(Duration disposalTime, int numberOfGcCycles) {
    if (_disposalGcCount == null || _gcedGcCount == null) return false;
    assert(_gcedTime != null);
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: _gcedGcCount!,
      currentTime: _gcedTime!,
      disposalTime: disposalTime,
      numberOfGcCycles: numberOfGcCycles,
    );
  }

  bool isNotGCedLeak(
    int currentGcCount,
    DateTime currentTime,
    Duration disposalTime,
    int numberOfGcCycles,
  ) {
    if (_gcedGcCount != null) return false;
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: currentGcCount,
      currentTime: currentTime,
      disposalTime: disposalTime,
      numberOfGcCycles: numberOfGcCycles,
    );
  }

  bool get isNotDisposedLeak {
    return isGCed && !isDisposed;
  }

  void setContext(String key, Object value) {
    final theContext = context ?? {};
    theContext[key] = value;
    context = theContext;
  }

  void mergeContext(Map<String, dynamic>? addedContext) {
    if (addedContext == null) return;
    final theContext = context;
    if (theContext == null) {
      context = addedContext;
      return;
    }
    theContext.addAll(addedContext);
  }

  LeakReport toLeakReport() => LeakReport(
        type: type.toString(),
        context: context,
        code: code,
        trackedClass: trackedClass,
        phase: phase.name,
      );
}
