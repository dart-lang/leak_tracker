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
    'References, retaining object from garbage collection.',
  );
  for (final RetainingObject item in retainingPath.elements?.reversed ?? []) {
    buffer.writeln(_retainingObjectToString(item));
  }
  return buffer.toString();
}

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
  ;

  const RetainingObjectProperty(this.pathes);

  final List<List<String>> pathes;
}

String _retainingObjectToString(RetainingObject object) {
  final json = object.toJson();

  var result = property(RetainingObjectProperty.type, json) ?? '';

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
  for (final path in property.pathes) {
    final value = _valueByPath(json, path);
    if (value != null && value != '') {
      return value;
    }
  }
  return null;
}

String? _valueByPath(Map<String, dynamic> json, List<String> path) {
  var parent = json;
  for (final String key in path.sublist(0, path.length - 1)) {
    final child = parent[key];
    if (child is Map<String, dynamic>) {
      parent = child;
    } else {
      return null;
    }
  }
  return parent[path.last];
}
