// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Test only function that creates a leaking object.
///
/// If test helpers are ignored in leak tracking settings,
/// leaks from objects created by this function will be ignored.
void createLeakingWidget() => StatelessLeakingWidget();
