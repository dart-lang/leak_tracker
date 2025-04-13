// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';

void main(List<String> arguments) {
  LeakTracking.start();
  print('Hello, world!');
  LeakTracking.stop();
}
