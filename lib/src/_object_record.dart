// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_gcCounter.dart';
import '_primitives.dart';
import 'model.dart';

/// Object collections to track leaks.
///
/// Objects migrate between collections based on their state.
///
/// On registration, each object enters all collections [notGCed]
/// and [notGCedFresh].
///
/// If the object stays not GCed after disposal too long,
/// it migrates from [notGCedFresh] to [notGCedLate].
///
/// If the object gets GCed, it is removed from all _notGCed... collections,
/// and, if it was GCed wrongly, added to one of _gced... collections.
class ObjectRecords {
  final Map<IdentityHashCode, ObjectRecord> notGCed =
      <IdentityHashCode, ObjectRecord>{};
  final Set<IdentityHashCode> notGCedFresh = <IdentityHashCode>{};
  final Set<IdentityHashCode> notGCedLate = <IdentityHashCode>{};

  final List<ObjectRecord> gcedLateLeaks = <ObjectRecord>[];
  final List<ObjectRecord> gcedNotDisposedLeaks = <ObjectRecord>[];
}

/// Information about an object, tracked for leaks.
class ObjectRecord {
  ObjectRecord(this.code, this.context, this.type);

  final IdentityHashCode code;
  final Map<String, dynamic> context;
  final Type type;

  DateTime? _disposalTime;
  int? _disposalGcCount;

  void setDisposed(int gcTime) {
    if (_disposalGcCount != null) throw 'The object $code was disposed twice.';
    if (_gcedGcTime != null)
      throw 'The object $code should not be disposed after being GCed.';
    _disposalGcCount = gcTime;
    _disposalTime = DateTime.now();
  }

  DateTime? _gcedTime;
  int? _gcedGcTime;
  void setGCed(int gcTime) {
    if (_gcedGcTime != null) throw 'The object $code GCed twice.';
    _gcedGcTime = gcTime;
    _gcedTime = DateTime.now();
  }

  bool get isGCed => _gcedGcTime != null;
  bool get isDisposed => _disposalGcCount != null;

  bool get isGCedLateLeak {
    if (_disposalGcCount == null || _gcedGcTime == null) return false;
    assert(_gcedTime != null);
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: _gcedGcTime!,
      currentTime: _gcedTime!,
    );
  }

  bool isNotGCedLeak(int currentGcCount) {
    if (_gcedGcTime != null) return false;
    return shouldObjectBeGced(
      gcCountAtDisposal: _disposalGcCount!,
      timeAtDisposal: _disposalTime!,
      currentGcCount: currentGcCount,
      currentTime: DateTime.now(),
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
