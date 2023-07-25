// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../leak_tracker.dart';
import '../shared/_primitives.dart';
import '../devtools_integration/_registration.dart';
import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_dispatcher.dart' as dispatcher;
import '_leak_checker.dart';
import '_object_tracker.dart';
import 'model.dart';

abstract class LeakTracking {
  static LeakTracker? _leakTracker;

  /// Leak provider, used in integration with DevTools.
  ///
  /// It should be updated every time leak tracking is reconfigured.
  static final _leakProvider = ObjectRef<LeakProvider?>(null);
}
