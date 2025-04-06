// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import '_formatting.dart';
import '_primitives.dart';

class ContextKeys {
  static const startCallstack = 'start';
  static const disposalCallstack = 'disposal';
  static const retainingPath = 'path';
}

enum LeakType {
  /// Not disposed and garbage collected.
  notDisposed,

  /// Disposed and not garbage collected when expected.
  notGCed,

  /// Disposed and garbage collected later than expected.
  gcedLate;

  static LeakType byName(String name) => LeakType.values.byName(name);
}

/// Names for json fields.
class _JsonFields {
  static const String type = 'type';
  static const String trackedClass = 'tracked';
  static const String context = 'context';
  static const String code = 'code';
  static const String time = 'time';
  static const String totals = 'totals';
  static const String phase = 'phase';
}

abstract class LeakProvider {
  Future<LeakSummary> leaksSummary();
  Future<Leaks> collectLeaks();
  Future<void> checkNotGCed();
}

/// Statistical information about found leaks.
class LeakSummary {
  LeakSummary(this.totals, {DateTime? time}) {
    this.time = time ?? DateTime.now();
  }

  factory LeakSummary.fromJson(Map<String, dynamic> json) => LeakSummary(
        (json[_JsonFields.totals] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            LeakType.byName(key),
            int.parse(value as String),
          ),
        ),
        time:
            DateTime.fromMillisecondsSinceEpoch(json[_JsonFields.time] as int),
      );

  final Map<LeakType, int> totals;

  late final DateTime time;

  int get total => totals.values.sum;

  bool get isEmpty => total == 0;

  String toMessage() {
    return '${totals.values.sum} memory leak(s): '
        'not disposed: ${totals[LeakType.notDisposed]}, '
        'not GCed: ${totals[LeakType.notGCed]}, '
        'GCed late: ${totals[LeakType.gcedLate]}';
  }

  Map<String, dynamic> toJson() => {
        _JsonFields.totals:
            totals.map((key, value) => MapEntry(key.name, value.toString())),
        _JsonFields.time: time.millisecondsSinceEpoch,
      };

  bool matches(LeakSummary? other) =>
      other != null &&
      const DeepCollectionEquality().equals(totals, other.totals);
}

/// Detailed information about found leaks.
class Leaks {
  Leaks(this.byType);

  Leaks.empty() : this({});

  factory Leaks.fromJson(Map<String, dynamic> json) => Leaks(
        json.map(
          (key, value) => MapEntry(
            LeakType.byName(key),
            (value as List)
                .cast<Map<String, dynamic>>()
                .map(LeakReport.fromJson)
                .toList(growable: false),
          ),
        ),
      );

  final Map<LeakType, List<LeakReport>> byType;

  List<LeakReport> get notGCed => byType[LeakType.notGCed] ?? [];
  List<LeakReport> get notDisposed => byType[LeakType.notDisposed] ?? [];
  List<LeakReport> get gcedLate => byType[LeakType.gcedLate] ?? [];
  List<LeakReport> get all => byType.values.flattened.toList();

  Map<String, dynamic> toJson() => byType.map(
        (key, value) =>
            MapEntry(key.name, value.map((e) => e.toJson()).toList()),
      );

  int get total => byType.values.map((e) => e.length).sum;

  late final Map<String?, Leaks> byPhase = () {
    final leaks = <String?, Map<LeakType, List<LeakReport>>>{};
    for (final entry in byType.entries) {
      for (final leak in entry.value) {
        leaks
            .putIfAbsent(leak.phase, () => {})
            .putIfAbsent(entry.key, () => <LeakReport>[])
            .add(leak);
      }
    }
    return {
      for (final entry in leaks.entries) entry.key: Leaks(entry.value),
    };
  }();

  String toYaml({required bool phasesAreTests}) {
    if (total == 0) return '';
    final leaks = LeakType.values
        .map(
          (e) => LeakReport.iterableToYaml(
            e.name,
            byType[e] ?? [],
            phasesAreTests: phasesAreTests,
          ),
        )
        .join();
    return '${leakTrackerYamlHeader()}$leaks';
  }
}

/// Leak information for troubleshooting.
class LeakReport {
  LeakReport({
    required this.trackedClass,
    required this.context,
    required this.code,
    required this.type,
    required this.phase,
  });

  factory LeakReport.fromJson(Map<String, dynamic> json) => LeakReport(
        type: json[_JsonFields.type] as String,
        context: json[_JsonFields.context] as Map<String, dynamic>? ?? {},
        code: json[_JsonFields.code] as int,
        trackedClass: json[_JsonFields.trackedClass] as String? ?? '',
        phase: json[_JsonFields.phase] as String?,
      );

  /// Information about the leak that can help in troubleshooting.
  ///
  /// Use [ContextKeys] to access predefined keys.
  final Map<String, dynamic>? context;

  /// [identityHashCode] of the object.
  final int code;

  /// Runtime type of the object.
  final String type;

  /// Full name of class, the leak tracking is defined for.
  ///
  /// Usually [trackedClass] is expected to be a supertype of [type].
  final String trackedClass;

  final String? phase;

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
    required bool phasesAreTests,
  }) {
    if (leaks == null || leaks.isEmpty) return '';

    return '''$title:
$indent  total: ${leaks.length}
$indent  objects:
${leaks.map((e) => e.toYaml('$indent    ', phasesAreTests: phasesAreTests)).join()}
''';
  }

  String toYaml(String indent, {required bool phasesAreTests}) {
    final result = StringBuffer();
    result.writeln('$indent$type:');
    if (phase != null) {
      final fieldName = phasesAreTests ? 'test' : 'phase';
      result.writeln('$indent  $fieldName: $phase');
    }
    result.writeln('$indent  identityHashCode: $code');
    final theContext = context;
    if (theContext != null && theContext.isNotEmpty) {
      result.writeln('$indent  context:');
      final contextIndent = '$indent    ';
      result.write(
        theContext.keys.map((key) {
          final value = _toMultiLineYamlString(
            contextToString(theContext[key]),
            '  $contextIndent',
          );
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

  static String _toMultiLineYamlString(String text, String indent) {
    if (!text.contains('\n')) return text;
    text = text.replaceAll('\n', '\n$indent').trimRight();
    return '>\n$indent$text';
  }
}
