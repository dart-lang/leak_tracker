// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';

/// Returns retaining path for an object, if it can be detected.
///
/// If [object] is null or object reference cannot be obtained or
/// isolate cannot be obtained, returns null.
Future<RetainingPath?> retainingPathImpl(
  VmService service,
  Object? object,
) async {
  return null;
}
