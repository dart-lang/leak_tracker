// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Frames pointing the folder `test` or the package `flutter_test`.
final _testHelperFrame = RegExp(
  r'(?:' +
      RegExp.escape(r'/test/') +
      r'|' +
      RegExp.escape(r'(package:flutter_test/') +
      r')',
);

/// Frames that match [_testHelperFrame], but are not test helpers.
final _exceptions = RegExp(
  r'(?:'
  r'AutomatedTestWidgetsFlutterBinding.\w|'
  r'TestWidgetsFlutterBinding.\w|'
  r'TestAsyncUtils.\w|'
  r'WidgetTester.\w|'
  r'testWidgets.<anonymous closure>'
  ')',
);

/// Test body or closure inside test body.
final _startFrame = RegExp(
  r'(?:'
  r'TestAsyncUtils.guard.<anonymous closure>|'
  r' main.<anonymous closure>'
  r')',
);

/// Returns whether the leak reported by [objectCreationTrace]
/// was created by a test helper.
///
/// Frames, that match [exceptions] will be ignored.
///
/// See details on what means to be created by a test helper
/// in doc for `LeakTesting.createdByTestHelpers`.
@visibleForTesting
bool isCreatedByTestHelper(
  String objectCreationTrace,
  List<RegExp> exceptions,
) {
  final frames = objectCreationTrace.split('\n');
  for (final frame in frames) {
    if (_startFrame.hasMatch(frame)) {
      return false;
    }
    if (_testHelperFrame.hasMatch(frame)) {
      if (exceptions.any((exception) => exception.hasMatch(frame)) ||
          _exceptions.hasMatch(frame)) {
        continue;
      }
      return true;
    }
  }
  return false;
}

/// Postponed detector of test helpers.
///
/// It is used to detect if the leak was created by a test helper,
/// only if the leak is detected.
///
/// It is needed because the detection is a heavy operation
/// and should not be done for every tracked object.
class CreationChecker {
  /// Creates instance of [CreationChecker].
  ///
  /// Stack frames in [creationStack] that match any of [exceptions]
  /// will be ignored.
  CreationChecker(
      {required StackTrace creationStack, required List<RegExp> exceptions})
      : _creationStack = creationStack,
        _exceptions = exceptions;
  StackTrace? _creationStack;
  List<RegExp>? _exceptions;

  /// True, if the leak was created by a test helper.
  ///
  /// This value is cached. The first calculation of the value
  /// is performance heavy.
  late final bool createdByTestHelpers = () {
    final result = isCreatedByTestHelper(
      _creationStack!.toString(),
      _exceptions!,
    );
    // Nulling the references to make the object eligible for GC.
    _creationStack = null;
    _exceptions = null;
    return result;
  }();
}
