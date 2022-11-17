// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/src/_object_tracker.dart';
import 'package:mockito/annotations.dart';

/// Run `dart run build_runner build` to regenerate mocks.
@GenerateNiceMocks([MockSpec<ObjectTracker>()])
void main() {}
