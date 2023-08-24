// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

class Lyfecycle<T> {
  const Lyfecycle(this.create, this.dispose);

  final T Function() create;
  final void Function(T) dispose;
}

/// Checks if the class is instrumented for leak tracking.
const Matcher isInstrumented = _IsInstrumented();

class _IsInstrumented extends Matcher {
  const _IsInstrumented();

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Lyfecycle) {
      return false;
    }
  }

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
          'The matcher applies to $Leaks and cannot be applied to ${item.runtimeType}',
        );
    }

    return mismatchDescription
      ..add('contains leaks:\n${item.toYaml(phasesAreTests: true)}');
  }

  @override
  Description describe(Description description) => description.add('leak free');
}
