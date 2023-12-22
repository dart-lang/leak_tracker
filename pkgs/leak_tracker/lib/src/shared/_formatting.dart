// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import '_primitives.dart';
import '_util.dart';

/// Converts item in leak tracking context to string.
String contextToString(Object? object) {
  return switch (object) {
    StackTrace() => _formatStackTrace(object),
    RetainingPath() => retainingPathToString(object),
    _ => object.toString(),
  };
}

String _formatStackTrace(StackTrace stackTrace) {
  var result = stackTrace.toString();

  result = removeLeakTrackingLines(result);

  // Remove spaces.
  // Spaces need to be removed from stacktrace
  // because otherwise test framework changes formatting
  // of a message from matcher.
  result = result.replaceAll(' ', '_');

  return result;
}

/// Removes top lines that relate to leak_tracker.
String removeLeakTrackingLines(String stackTrace) {
  final lines = stackTrace.split('\n');
  var firstUserCode = 0;
  while (firstUserCode < lines.length &&
      lines[firstUserCode].contains(leakTrackerStackTraceFragment)) {
    firstUserCode++;
  }
  lines.removeRange(0, firstUserCode);
  return lines.join('\n');
}

String retainingPathToString(RetainingPath retainingPath) {
  final buffer = StringBuffer();
  buffer.writeln(
    'References that retain the object from garbage collection.',
  );
  for (final item in retainingPath.elements?.reversed ?? <RetainingObject>[]) {
    buffer.writeln(_retainingObjectToString(item));
  }
  return buffer.toString();
}

/// Properties of [RetainingObject] that are needed in the object's formatting.
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
  closureOwner([
    ['value', 'closureFunction', 'owner', 'name'],
  ]),
  globalVarUri([
    ['value', 'location', 'script', 'uri'],
  ]),
  globalVarName([
    ['value', 'name'],
  ]);

  const RetainingObjectProperty(this.paths);

  /// Itemizes possible paths in [RetainingObject.toJson] to
  /// get the value of a property.
  final List<List<String>> paths;
}

String _retainingObjectToString(RetainingObject object) {
  final json = object.toJson();

  var result = property(RetainingObjectProperty.type, json) ?? '';

  if (result == '_Closure') {
    final func = property(RetainingObjectProperty.closureOwner, json);
    if (func != null) {
      result = '$result (in $func)';
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

  if (result == 'dart.core/_Type') {
    final globalVarUri = property(RetainingObjectProperty.globalVarUri, json);
    final globalVarName = property(RetainingObjectProperty.globalVarName, json);
    result = '$globalVarUri/$globalVarName';
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
