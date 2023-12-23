// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This function is better than `as`,
/// because `as` does not provide callstack on failure.
T cast<T>(Object? value) {
  if (value is T) return value;
  throw ArgumentError(
    '$value is of type ${value.runtimeType} that is not a subtype of $T',
  );
}

extension IterableExtensions<T> on Iterable<T> {
  /// Returns the item or null, assuming that
  /// the length of the iterable is 0 or 1.
  // The name is consistent with other method names on iterables like
  // `firstOrNull, lastOrNull, and singleOrNull`.
  T? get onlyOrNull {
    if (length > 1) throw StateError('Length should not be more than one.');
    return firstOrNull;
  }
}

void printToConsole(Object message) {
  // ignore: avoid_print, dart:io is not available in web
  print('leak_tracker: $message');
}

extension SizeConversion on int {
  int get mbToBytes => this * 1024 * 1024;
}

extension StringChecks on String? {
  bool get isNullOrEmpty => this == null || this == '';
}
