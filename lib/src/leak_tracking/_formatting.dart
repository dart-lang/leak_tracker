// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import '../shared/_util.dart';

/// Converts item in leak tracking context to string.
String contextToString(Object? object) {
  return switch (object) {
    // Spaces need to be removed from stacktrace
    // because otherwise test framework changes formatting
    // of a message from matcher.
    StackTrace() => object.toString().replaceAll(' ', '_'),
    RetainingPath() => _retainingPathToString(object),
    _ => object.toString(),
  };
}

String _retainingPathToString(RetainingPath retainingPath) {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln(
    'References that retain the object from garbage collection.',
  );
  for (final item in retainingPath.elements?.reversed ?? <RetainingObject>[]) {
    buffer.writeln(_retainingObjectToString(item));
  }
  return buffer.toString();
}

/// Proprties of [RetainingObject] that are needed in the object's formatting.
enum RetainingObjectProperty {
  lib([
    ['value', 'class', 'library', 'name'],
    ['value', 'class', 'library', 'uri'],
    ['value', 'declaredType', 'class', 'library', 'name'],
    ['value', 'declaredType', 'class', 'library', 'uri'],
  ]),
  type([
    ['value', 'class', 'name'],
    ['value', 'declaredType', 'class', 'name'],
    ['value', 'type'],
  ]),
  func([
    ['value', 'closureFunction', 'owner', 'name'],
  ]);

  const RetainingObjectProperty(this.paths);

  /// Itemizes possible paths in [RetainingObject.toJson] to get the value of a property.
  final List<List<String>> paths;
}

String _retainingObjectToString(RetainingObject object) {
  final json = object.toJson();

  var result = property(RetainingObjectProperty.type, json) ?? '';

  if (result == '_Closure') {
    final func = property(RetainingObjectProperty.func, json);
    if (func != null) {
      result += '(in $func)';
    }
  }

  final lib = property(RetainingObjectProperty.lib, json);
  if (lib != null) {
    result = '$lib/$result';
  }

  final location =
      object.parentField ?? object.parentMapKey ?? object.parentListIndex;

  if (location != null) {
    result = '$result:$location';
  }

  return result;
}

String? property(
  RetainingObjectProperty property,
  Map<String, dynamic> json,
) {
  for (final path in property.paths) {
    final value = _valueByPath(json, path);
    if (!value.isNullOrEmpty) {
      return value;
    }
  }
  return null;
}

String? _valueByPath(Map<String, dynamic> json, List<String> path) {
  var parent = json;
  for (final key in path.sublist(0, path.length - 1)) {
    final child = parent[key];
    if (child is Map<String, dynamic>) {
      parent = child;
    } else {
      return null;
    }
  }

  // [path.last] contains the key for actual value.
  final value = parent[path.last];

  return value?.toString();
}
