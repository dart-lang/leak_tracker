// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Compares two maps for element-by-element equality.
///
/// Copied from
/// https://github.com/flutter/flutter/blob/37b72342b0ce86fbfc238a9d43e524608b89af3a/packages/flutter/lib/src/foundation/collections.dart#L22
bool mapEquals<T, U>(Map<T, U>? a, Map<T, U>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (final T key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}

/// This function is better than `as`, because `as` does not provide callstack on failure.
T cast<T>(value) {
  if (value is T) return value;
  throw ArgumentError(
    '$value is of type ${value.runtimeType} that is not subtype of $T',
  );
}

String contextToString(Object? object) {
  // Spaces need to be removed from stacktrace
  // because otherwise test framework changes formatting
  // of a message from matcher.
  if (object is StackTrace) {
    return object.toString().replaceAll(' ', '_');
  }

  return object.toString();
}

void printToConsole(Object message) {
  // ignore: avoid_print, dart:io is not available in web
  print('leak_tracker: $message');
}

extension SizeConversion on int {
  int mbToBytes() => this * 1024 * 1024;
}
