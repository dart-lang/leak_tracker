// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks if the object dispatches events to `MemoryAllocations.instance`.
///
/// [createAndDispose] should create and dispose the object.
Matcher dispatchesMemoryEvents(Function() createAndDispose) =>
    _DispatchesMemoryEvents(createAndDispose);

class _DispatchesMemoryEvents extends Matcher {
  const _DispatchesMemoryEvents(this.createAndDispose);

  final Function() createAndDispose;
  static const _key = 'description';

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Type) {
      matchState[_key] = 'The matcher applies to $Type.';
      return false;
    }

    final events = <ObjectEvent>[];

    void listener(ObjectEvent event) {
      if (event.object.runtimeType == item) {
        events.add(event);
      }
    }

    MemoryAllocations.instance.addListener(listener);
    createAndDispose();
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
        'Actually it dispatched ${events.length} events:\n$events';

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
