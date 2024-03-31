// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import 'primitives/_gc_counter.dart';
import 'primitives/_test_helper_detector.dart';
import 'primitives/model.dart';

/// Information about an object, tracked for leaks.
class ObjectRecord {
  ObjectRecord(
    Object object,
    this.context,
    this.trackedClass,
    this.phase, {
    this.creationChecker,
  })  : ref = WeakReference(object),
        type = object.runtimeType,
        code = identityHashCode(object);

  /// Weak reference to the tracked object.
  final WeakReference<Object> ref;

  /// [IdentityHashCode] of the object.
  ///
  /// Is needed to help debugging notDisposed leak, for which
  /// the object is already GCed and thus there is no access to its code.
  final IdentityHashCode code;

  /// [CreationChecker] that contains knowledge about creation.
  ///
  /// Is not used in the record, but can be used
  /// by owners of this object.
  final CreationChecker? creationChecker;

  Map<String, dynamic>? context;

  final PhaseSettings phase;

  /// Runtime type of the tracked object.
  final Type type;

  final String trackedClass;

  DateTime? _disposalTime;
  int? _disposalGcCount;

  void setDisposed(int gcTime, DateTime time) {
    if (_disposalGcCount != null) {
      // It is not responsibility of leak tracker to check for double disposal.
      return;
    }
    if (_gcedGcCount != null) {
      throw Exception(
          'The object $code should not be disposed after being GCed');
    }
    _disposalGcCount = gcTime;
    _disposalTime = time;
  }

  DateTime? _gcedTime;
  int? _gcedGcCount;
  void setGCed(int gcCount, DateTime time) {
    if (_gcedGcCount != null) {
      throw Exception('$trackedClass, $code is GCed twice');
    }
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
