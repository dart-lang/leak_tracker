// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:matcher/matcher.dart';

/// Checks if the leak collection is empty.
const Matcher isLeakFree = _IsLeakFree();

class _IsLeakFree extends Matcher {
  const _IsLeakFree();

  @override
  bool matches(Object? item, Map matchState) =>
      item is Leaks && item.total == 0;

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! Leaks) {
      return mismatchDescription
        ..add(
          'The matcher applies to $Leaks and cannot be '
          'applied to ${item.runtimeType}',
        );
    }

    return mismatchDescription
      ..add('contains leaks:\n${item.toYaml(phasesAreTests: true)}');
  }

  @override
  Description describe(Description description) => description.add('leak free');
}
