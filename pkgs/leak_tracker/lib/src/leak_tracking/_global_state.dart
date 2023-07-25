// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Writable global settings for leak tracker, as it is ok for enum-like classes.
class InternalGlobalState {
  static bool isTrackingInProcess = false;

  static bool isTrackingPaused = false;

  static String? phase;
}
