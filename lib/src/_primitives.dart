// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Result of [identityHashCode].
typedef IdentityHashCode = int;

typedef ObjectGcCallback = void Function(Object code);

typedef FinalizerBuilder = Finalizer<Object> Function(
  ObjectGcCallback onObjectGc,
);

Finalizer<Object> buildFinalizer(ObjectGcCallback onObjectGc) =>
    Finalizer<Object>(onObjectGc);
