// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_gc_counter.dart';
import '_primitives.dart';
import 'model.dart';

/// Object collections to track leaks.
///
/// Objects migrate between collections based on their state.
///
/// On registration, each object enters the collections [notGCed].
/// On disposal it is added to disposedOk. Then, if it is overdue
/// to be GCed it migrates from [notGCedDisposedOk] to [notGCedDisposedLate].
///
/// If the object gets GCed, it is removed from all notGCed... collections,
/// and, if it was GCed wrongly, added to one of gced... collections.
class ObjectRecords {
  /// All not GCed objects.
  final Map<IdentityHashCode, ObjectRecord> notGCed =
      <IdentityHashCode, ObjectRecord>{};

  /// Not GCed objects, that were disposed and are not expected to be GCed yet.
  final Set<IdentityHashCode> notGCedDisposedOk = <IdentityHashCode>{};

  /// Not GCed objects, that were disposed and are overdue to be GCed.
  final Set<IdentityHashCode> notGCedDisposedLate = <IdentityHashCode>{};

  /// GCed objects that were late to be GCed.
  final List<ObjectRecord> gcedLateLeaks = <ObjectRecord>[];

  /// GCed ibjects that were not disposed.
  final List<ObjectRecord> gcedNotDisposedLeaks = <ObjectRecord>[];

  /// As identityHashCode is not unique, we ignore objects that happen to have
  /// equal code.
  final Set<IdentityHashCode> duplicates = <int>{};
}

/// Information about an object, tracked for leaks.
class ObjectRecord {
  ObjectRecord(this.code, this.context, this.type);

  final IdentityHashCode code;
  final Map<String, dynamic> context;
  final Type type;

  DateTime? _disposalTime;
  int? _disposalGcCount;

  void setDisposed(int gcTime, DateTime time) {
    if (_disposalGcCount != null) throw 'The object $code was disposed twice.';
    if (_gcedGcCount != null)
      throw 'The object $code should not be disposed after being GCed.';
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

  bool get isGCedLateLeak {
    if (_disposalGcCount == null || _gcedGcCount == null) return false;
    assert(_gcedTime != null);
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: _gcedGcCount!,
      currentTime: _gcedTime!,
    );
  }

  bool isNotGCedLeak(int currentGcCount, DateTime currentTime) {
    if (_gcedGcCount != null) return false;
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: currentGcCount,
      currentTime: currentTime,
    );
  }

  bool get isNotDisposedLeak {
    return isGCed && !isDisposed;
  }

  LeakReport toLeakReport() => LeakReport(
        type: type.toString(),
        context: context,
        code: code,
      );
}
