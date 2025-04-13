// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'package:test/test.dart';

final _leaks = Leaks({
  LeakType.gcedLate: [
    LeakReport(
      trackedClass: 'trackedClass',
      context: {},
      code: 1,
      type: 'type',
      phase: null,
    ),
  ],
});

void main() {
  test('$isLeakFree passes.', () async {
    expect(Leaks({}), isLeakFree);
  });

  test('$isLeakFree fails.', () async {
    expect(isLeakFree.matches(_leaks, {}), false);
  });

  test('$isLeakFree fails.', () async {
    expect(isLeakFree.matches(_leaks, {}), false);
  });

  group('troubleshootingDocumentationLink', () {
    late String originalLink;
    setUp(() {
      originalLink = LeakTracking.troubleshootingDocumentationLink;
    });
    tearDown(() {
      LeakTracking.troubleshootingDocumentationLink = originalLink;
    });

    test('defaults to TROUBLESHOOT.md', () async {
      expect(LeakTracking.troubleshootingDocumentationLink,
          'https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/TROUBLESHOOT.md');
    });

    test('is preserved', () async {
      expect(LeakTracking.troubleshootingDocumentationLink, originalLink);
      LeakTracking.troubleshootingDocumentationLink = 'https://example.com';
      expect(
          LeakTracking.troubleshootingDocumentationLink, 'https://example.com');
    });

    test('is preserved', () async {
      expect(LeakTracking.troubleshootingDocumentationLink, originalLink);
      LeakTracking.troubleshootingDocumentationLink = 'https://example.com';
      expect(
          LeakTracking.troubleshootingDocumentationLink, 'https://example.com');
    });

    test('is used in leak report when default', () async {
      expect(LeakTracking.troubleshootingDocumentationLink, originalLink);
      checkLinkIsUsed();
    });

    test('is used in leak report when default', () async {
      LeakTracking.troubleshootingDocumentationLink =
          'https://custom_example.com';
      expect(LeakTracking.troubleshootingDocumentationLink,
          'https://custom_example.com');
      checkLinkIsUsed();
    });
  });
}

void checkLinkIsUsed() {
  final description = isLeakFree.describeMismatch(
      _leaks, StringDescription(), {}, false) as StringDescription;
  expect(description.toString(),
      contains(LeakTracking.troubleshootingDocumentationLink));
}
