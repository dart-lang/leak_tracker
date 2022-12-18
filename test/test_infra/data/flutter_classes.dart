// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'dart_classes.dart';

final notGcedStorage = <InstrumentedClass>[];

InstrumentedClass notGCed = InstrumentedClass();

class StatelessLeakingWidget extends StatelessWidget {
  StatelessLeakingWidget({super.key}) {
    // ignore: unused_local_variable
    final notDisposed = InstrumentedClass();
    notGcedStorage.add(InstrumentedClass()..dispose());
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

/// The class creates and does not dispose ValueNotifier.
class ValueNotifierNotDisposer {
  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(false);
}
