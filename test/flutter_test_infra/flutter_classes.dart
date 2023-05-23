// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../dart_test_infra/data/dart_classes.dart';

final notGcedStorage = <InstrumentedClass>[];

InstrumentedClass notGCed = InstrumentedClass();

class StatelessLeakingWidget extends StatelessWidget {
  StatelessLeakingWidget({
    super.key,
    this.notGCed = true,
    this.notDisposed = true,
  }) {
    if (notGCed) {
      notGcedStorage.add(InstrumentedClass()..dispose());
    }
    if (notDisposed) {
      // ignore: unused_local_variable
      final notDisposedObject = InstrumentedClass();
    }
  }

  final bool notGCed;
  final bool notDisposed;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
