// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

/// Converts item in leak tracking context to string.
String contextToString(Object? object) {
  // Spaces need to be removed from stacktrace
  // because otherwise test framework changes formatting
  // of a message from matcher.
  if (object is StackTrace) {
    return object.toString().replaceAll(' ', '_');
  }

  if (object is RetainingPath) {
    return _retainingPathToString(object);
  }

  return object.toString();
}

String _retainingPathToString(RetainingPath retainingPath) {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln(
    'Chain of references from app root, that retain the object from garbage collection:',
  );
  for (final RetainingObject item in retainingPath.elements ?? []) {
    buffer.writeln(
        '${item.parentField},${item.parentMapKey},${item.parentListIndex}, ${item.value}, ${item.toJson()}');
  }
  return buffer.toString();
}
