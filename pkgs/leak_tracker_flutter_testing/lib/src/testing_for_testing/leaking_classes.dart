// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:leak_tracker/leak_tracker.dart';

final _notGcedStorage = <InstrumentedDisposable>[];

/// Example of stateless leaking widget.
class StatelessLeakingWidget extends StatelessWidget {
  StatelessLeakingWidget({
    super.key,
    this.notGCed = true,
    this.notDisposed = true,
  }) {
    if (notGCed) {
      _notGcedStorage.add(InstrumentedDisposable()..dispose());
    }
    if (notDisposed) {
      // ignore: unused_local_variable
      final notDisposedObject = InstrumentedDisposable();
    }
  }

  final bool notGCed;
  final bool notDisposed;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

/// Example of instrumented disposable.
class InstrumentedDisposable {
  InstrumentedDisposable() {
    LeakTracking.dispatchObjectCreated(
      library: library,
      className: '$InstrumentedDisposable',
      object: this,
    );
  }

  static const library = 'package:my_package/lib/src/my_lib.dart';

  void dispose() {
    LeakTracking.dispatchObjectDisposed(object: this);
  }
}

final _notGCedObjects = <InstrumentedDisposable>[];

/// Example of leaking class.
class LeakingClass {
  LeakingClass() {
    _notGCedObjects.add(InstrumentedDisposable()..dispose());
  }
}
