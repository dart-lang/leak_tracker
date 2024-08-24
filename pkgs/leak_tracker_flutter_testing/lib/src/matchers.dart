// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matcher/matcher.dart';

/// Invokes [callback] and collects
/// events dispatched to [FlutterMemoryAllocations.instance] for [type].
Future<List<ObjectEvent>> memoryEvents(
  FutureOr<void> Function() callback,
  Type type,
) async {
  final events = <ObjectEvent>[];

  void listener(ObjectEvent event) {
    if (event.object.runtimeType == type) {
      events.add(event);
    }
  }

  FlutterMemoryAllocations.instance.addListener(listener);
  await callback();
  FlutterMemoryAllocations.instance.removeListener(listener);

  return events;
}

/// Checks if `Iterable<ObjectEvent>` contains two events,
/// first `ObjectCreated` and then `ObjectDisposed`.
Matcher areCreateAndDispose = const _AreCreateAndDispose();

class _AreCreateAndDispose extends Matcher {
  const _AreCreateAndDispose();

  static const _key = 'description';

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Iterable<ObjectEvent>) {
      matchState[_key] = 'The matcher applies to $Iterable<$ObjectEvent>.';
      return false;
    }

    if (item.length == 2 &&
        item.first is ObjectCreated &&
        item.last is ObjectDisposed) {
      return true;
    }

    matchState[_key] = 'The events are expected to be first '
        '$ObjectCreated and then $ObjectDisposed.\n'
        'Instead, they are ${item.length} events:\n$item.';

    return false;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    return mismatchDescription..add(matchState[_key] as String);
  }

  @override
  Description describe(Description description) =>
      description.add('instrumented');
}
