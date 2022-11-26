// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The library should be used by DevTools to analyse the collected leaks.
///
/// Should not be used in the application itself.
library leak_analysis;

export 'src/devtools_integration/from_app.dart';
export 'src/devtools_integration/model.dart';
export 'src/devtools_integration/to_app.dart';
