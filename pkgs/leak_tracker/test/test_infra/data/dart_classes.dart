// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:new_leak_tracker/leak_tracker.dart';

class Named {
  Named(this.name);

  final String name;
}

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

class LeakingClass {
  LeakingClass() {
    // Not gced:
    _notGCedObjects.add(LeakTrackedClass()..dispose());

    // Not disposed:
    LeakTrackedClass();
  }
}
