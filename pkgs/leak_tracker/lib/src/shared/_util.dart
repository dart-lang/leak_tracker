// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This function is better than `as`, because `as` does not provide callstack on failure.
T cast<T>(value) {
  if (value is T) return value;
  throw ArgumentError(
    '$value is of type ${value.runtimeType} that is not subtype of $T',
  );
}

void printToConsole(Object message) {
  // ignore: avoid_print, dart:io is not available in web
  print('leak_tracker: $message');
}

extension SizeConversion on int {
  int mbToBytes() => this * 1024 * 1024;
}

extension StringChecks on String? {
  bool get isNullOrEmpty => this == null || this == '';
}
