// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:leak_tracker/leak_tracker.dart';

// The classes are declared not under `test` to test [IgnoredLeaks.testHelpers].

final _notGcedStorage = <LeakTrackedClass>[];

@visibleForTesting
class StatelessLeakingWidget extends StatelessWidget {
  StatelessLeakingWidget({
    super.key,
    this.notGCed = true,
    this.notDisposed = true,
  }) {
    if (notGCed) {
      _notGcedStorage.add(LeakTrackedClass()..dispose());
    }
    if (notDisposed) {
      // ignore: unused_local_variable
      final notDisposedObject = LeakTrackedClass();
    }
  }

  final bool notGCed;
  final bool notDisposed;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

@visibleForTesting
class LeakTrackedClass {
  LeakTrackedClass() {
    LeakTracking.dispatchObjectCreated(
      library: library,
      className: '$LeakTrackedClass',
      object: this,
    );
  }

  static const library = 'package:my_package/lib/src/my_lib.dart';

  void dispose() {
    LeakTracking.dispatchObjectDisposed(object: this);
  }
}

final _notGCedObjects = <LeakTrackedClass>[];

@visibleForTesting
class LeakingClass {
  LeakingClass() {
    _notGCedObjects.add(LeakTrackedClass()..dispose());
  }
}
