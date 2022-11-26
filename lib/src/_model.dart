// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'devtools_integration/model.dart';

abstract class LeakProvider {
  LeakSummary leaksSummary();
  Leaks collectLeaks();
}
