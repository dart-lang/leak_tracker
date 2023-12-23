// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import '_retaining_path_web.dart'
    if (dart.library.isolate) '_retaining_path_isolate.dart';

/// Returns retaining path for an object, if it can be detected.
///
/// If [object] is null or object reference cannot be obtained or
/// isolate cannot be obtained, returns null.
Future<RetainingPath?> retainingPath(
  VmService service,
  Object? object,
) async {
  return retainingPathImpl(service, object);
}
