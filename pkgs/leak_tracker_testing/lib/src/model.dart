// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Object lifecycle.
///
/// Is used to test if an object dispatched deeded events at creation and disposal.
class ObjectLyfecycle {
  ObjectLyfecycle(this.createAndDispose, this.objectType);

  /// Creates and disposes an object.
  final void Function() createAndDispose;

  /// Runtime type of the object.
  final Type objectType;
}
