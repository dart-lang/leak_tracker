// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:autosnapshotting/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Prerequisite to run for macos:
// flutter create --platforms=macos .

// Run for macos:
// flutter test integration_test/app_test.dart -d macos

// Run headless:
// flutter test integration_test/app_test.dart -d flutter-tester

const _testDirRoot = 'test_dart_snapshots';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Snapshots are not taken after reaching limit', (tester) async {
    app.main([], snapshotDirectory: '$_testDirRoot/$pid');
    await tester.pumpAndSettle();

    final pageState =
        tester.state<app.MyHomePageState>(find.byType(app.MyHomePage));
    final config = pageState.config;
    final theButton = find.byTooltip('Allocate more memory');

    // Take first snapshot
    final firstThreshold =
        config.autoSnapshottingConfig!.thresholdMb.mbToBytes();
    while (pageState.lastRss <= firstThreshold) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
    expect(pageState.snapshots.length, greaterThan(0));

    // Take second threshold
    final secondThreshold = pageState.lastRss +
        config.autoSnapshottingConfig!.increaseMb!.mbToBytes();
    int snapshotsLength = pageState.snapshots.length;
    while (pageState.lastRss <= secondThreshold) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
    expect(pageState.snapshots.length, snapshotsLength + 1);

    // Check the directory limit is respected.
    while (directorySize(config.autoSnapshottingConfig!.directory) <=
        config.autoSnapshottingConfig!.directorySizeLimitMb.mbToBytes()) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    }
    snapshotsLength = pageState.snapshots.length;
    for (var _ in Iterable.generate(10)) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    expect(pageState.snapshots, hasLength(snapshotsLength));

    expect(pageState.usageEvents.length, inInclusiveRange(4, 12));
  });

  tearDownAll(() {
    Directory(_testDirRoot).deleteSync(recursive: true);
  });
}

int directorySize(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => f.lengthSync())
    .fold<int>(0, (a, b) => a + b);
