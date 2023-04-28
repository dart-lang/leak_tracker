// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:autosnapshotting/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Run:
// flutter test integration_test/app_test.dart -d macos

extension _SizeConversion on int {
  int mbToBytes() => this * 1024 * 1024;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Snapshots are taken after reaching limit', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final pageState =
        tester.state<app.MyHomePageState>(find.byType(app.MyHomePage));
    final config = pageState.config;
    final theButton = find.byTooltip('Allocate more memory');

    // Take first snapshot
    final firstThreshold = config.thresholdMb.mbToBytes();
    while (pageState.lastRss <= firstThreshold) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
    expect(pageState.snapshots.length, greaterThan(0));

    //Take second threshold
    final secondThreshold = pageState.lastRss + config.stepMb!.mbToBytes();
    int snapshotsLength = pageState.snapshots.length;
    while (pageState.lastRss <= secondThreshold) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
    expect(pageState.snapshots.length, greaterThan(snapshotsLength + 1));

    //Check the directory limit is respected.
    while (directorySize(config.directory) <=
        config.directorySizeLimitMb.mbToBytes()) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    }
    snapshotsLength = pageState.snapshots.length;
    for (var _ in Iterable.generate(10)) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    expect(pageState.snapshots.length, snapshotsLength);
  });
}

int directorySize(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => f.lengthSync())
    .fold<int>(0, (a, b) => a + b);
