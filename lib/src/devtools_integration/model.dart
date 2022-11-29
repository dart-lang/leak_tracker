// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';

import '../_util.dart';

/// Name of extension to integrate the leak tracker with DevDools.
const String memoryLeakTrackingExtensionName = 'ext.dart.memoryLeakTracking';

/// Version of protocol, executed by the application.
const String appLeakTrackerProtocolVersion = '1';

ServiceExtensionResponse serviceResponse(
  ResponseType type, {
  Map<String, dynamic> details = const {},
}) =>
    ServiceExtensionResponse.result(jsonEncode({type.value: details}));

/// Instead of using ServiceExtensionResponse.error, we use success response,
/// because we do not want the error to be handled automatically.
enum ResponseType {
  success('success'),
  leakTrackingTurnedOff('leakTrackingTurnedOff'),
  unexpectedError('unexpectedError'),
  unexpectedEventType('unexpectedEventType');

  const ResponseType(this.value);

  final String value;
}

enum LeakType {
  /// Not disposed and garbage collected.
  notDisposed,

  /// Disposed and not garbage collected when expected.
  notGCed,

  /// Disposed and garbage collected later than expected.
  gcedLate,
}

LeakType _parseLeakType(String source) =>
    LeakType.values.firstWhere((e) => e.toString() == source);

/// Statistical information about found leaks.
class LeakSummary {
  const LeakSummary(this.totals);

  factory LeakSummary.fromJson(Map<String, dynamic> json) => LeakSummary(
        json.map(
          (key, value) => MapEntry(_parseLeakType(key), int.parse(value)),
        ),
      );

  final Map<LeakType, int> totals;

  int get total => totals.values.sum;

  bool get isEmpty => total == 0;

  String toMessage() {
    return '${totals.values.sum} memory leak(s): '
        'not disposed: ${totals[LeakType.notDisposed]}, '
        'not GCed: ${totals[LeakType.notGCed]}, '
        'GCed late: ${totals[LeakType.gcedLate]}';
  }

  Map<String, dynamic> toJson() =>
      totals.map((key, value) => MapEntry(key.toString(), value.toString()));

  bool matches(LeakSummary? other) =>
      other != null && mapEquals(totals, other.totals);
}

/// Detailed information about found leaks.
class Leaks {
  Leaks(this.byType);

  factory Leaks.fromJson(Map<String, dynamic> json) => Leaks(
        json.map(
          (key, value) => MapEntry(
            _parseLeakType(key),
            (value as List)
                .cast<Map<String, dynamic>>()
                .map((e) => LeakReport.fromJson(e))
                .toList(growable: false),
          ),
        ),
      );
  final Map<LeakType, List<LeakReport>> byType;

  List<LeakReport> get notGCed => byType[LeakType.notGCed] ?? [];
  List<LeakReport> get notDisposed => byType[LeakType.notDisposed] ?? [];
  List<LeakReport> get gcedLate => byType[LeakType.gcedLate] ?? [];

  Map<String, dynamic> toJson() => byType.map(
        (key, value) =>
            MapEntry(key.toString(), value.map((e) => e.toJson()).toList()),
      );

  int get total => byType.values.map((e) => e.length).sum;
}

/// Names for json fields.
class _JsonFields {
  static const String type = 'type';
  static const String trackedClass = 'tracked';
  static const String context = 'context';
  static const String code = 'code';
}

class ContextKeys {
  static const startCallstack = 'start';
  static const disposalCallstack = 'disposal';
}

/// Leak information, passed from application to DevTools and than extended by
/// DevTools after deeper analysis.
class LeakReport {
  LeakReport({
    required this.trackedClass,
    required this.context,
    required this.code,
    required this.type,
  });

  factory LeakReport.fromJson(Map<String, dynamic> json) => LeakReport(
        type: json[_JsonFields.type],
        context: (json[_JsonFields.context] as Map<String, dynamic>? ?? {})
            .cast<String, dynamic>(),
        code: json[_JsonFields.code],
        trackedClass: json[_JsonFields.trackedClass],
      );

  /// Information about the leak that can help in troubleshooting.
  final Map<String, dynamic>? context;

  /// [identityHashCode] of the object.
  final int code;

  /// Runtime type of the object.
  final String type;

  /// Full name of class, the leak tracking is defined for.
  ///
  /// Usually [trackedClass] is expected to be a supertype of [type].
  final String trackedClass;

  // The fields below do not need serialization as they are populated after.
  String? retainingPath;
  List<String>? detailedPath;

  Map<String, dynamic> toJson() => {
        _JsonFields.type: type,
        _JsonFields.context: context,
        _JsonFields.code: code,
        _JsonFields.trackedClass: trackedClass,
      };

  static String iterableToYaml(
    String title,
    Iterable<LeakReport>? leaks, {
    String indent = '',
  }) {
    if (leaks == null || leaks.isEmpty) return '';

    return '''$title:
$indent  total: ${leaks.length}
$indent  objects:
${leaks.map((e) => e.toYaml('$indent    ')).join()}
''';
  }

  String toYaml(String indent) {
    final result = StringBuffer();
    result.writeln('$indent$type:');
    result.writeln('$indent  identityHashCode: $code');
    final theContext = context;
    if (theContext != null && theContext.isNotEmpty) {
      result.writeln('$indent  context:');
      final contextIndent = '$indent    ';
      result.write(
        theContext.keys.map((key) {
          final value =
              _indentNewLines(jsonEncode(theContext[key]), '  $contextIndent');
          return '$contextIndent$key: $value\n';
        }).join(),
      );
    }

    if (detailedPath != null) {
      result.writeln('$indent  retainingPath:');
      result.writeln(detailedPath!.map((s) => '$indent    - $s').join('\n'));
    } else if (retainingPath != null) {
      result.writeln('$indent  retainingPath: $retainingPath');
    }
    return result.toString();
  }

  static String _indentNewLines(String text, String indent) {
    return text.replaceAll('\n', '\n$indent').trimRight();
  }
}
