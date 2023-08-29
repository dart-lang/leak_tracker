// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks if the object dispatches events to `MemoryAllocations.instance`.
///
/// The memory events are used by tools like leak_tracker for diagnostics.
///
/// The matcher checks that the object object is instrumented properly,
/// dispatches two events to `MemoryAllocations.instance`,
/// first `ObjectCreated` and then `ObjectDisposed`.
Matcher dispatchesMemoryEvents(Type type) {
  return _DispatchesMemoryEvents(type);
}

class _DispatchesMemoryEvents extends Matcher {
  const _DispatchesMemoryEvents(this.type);

  static const _key = 'description';
  final Type type;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Function()) {
      matchState[_key] = 'The matcher applies to `Function()`.';
      return false;
    }

    final events = <ObjectEvent>[];

    void listener(ObjectEvent event) {
      if (event.object.runtimeType == type) {
        events.add(event);
      }
    }

    MemoryAllocations.instance.addListener(listener);
    item();
    MemoryAllocations.instance.removeListener(listener);

    if (events.length == 2 &&
        events.first is ObjectCreated &&
        events.last is ObjectDisposed) {
      return true;
    }

    matchState[_key] =
        'createAndDispose is expected to dispatch two events to $MemoryAllocations.instance,'
        ' for the type $item,'
        ' first $ObjectCreated and then $ObjectDisposed.\n'
        'Instead, it dispatched ${events.length} events:\n$events';

    return false;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    return mismatchDescription..add(matchState[_key]);
  }

  @override
  Description describe(Description description) =>
      description.add('instrumented');
}
