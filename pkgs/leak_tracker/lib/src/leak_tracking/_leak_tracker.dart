// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../devtools_integration/_registration.dart';
import '../shared/_primitives.dart';
import '../shared/shared_model.dart';
import '_dispatcher.dart' as dispatcher;
import '_leak_reporter.dart';
import '_object_tracker.dart';
import 'model.dart';

class LeakTracker {
  final ObjectTracker _objectTracker;
  final LeakReporter _leakChecker;
}
