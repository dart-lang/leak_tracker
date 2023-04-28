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
    final theButton = find.byTooltip('Allocate more memory');

    // Take first snapshot
    final firstThreshold = app.memoryThresholdMb.mbToBytes();
    while (pageState.lastRss <= firstThreshold) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
    expect(pageState.snapshots.length, greaterThan(0));

    //Take second threshold
    final secondThreshold = pageState.lastRss + app.memoryStepMb.mbToBytes();
    final snapshotsLength = pageState.snapshots.length;
    while (pageState.lastRss <= secondThreshold) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
    expect(pageState.snapshots.length, greaterThan(snapshotsLength + 1));

    //Check the directory limit is respected.
    while (folderSize(pageState.directory) <=
        app.directorySizeLimitMb.mbToBytes()) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
    while (pageState.lastRss <= secondThreshold) {
      await tester.tap(theButton);
      await tester.pumpAndSettle();
    }
  });
}

int folderSize(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => f.lengthSync())
    .fold<int>(0, (a, b) => a + b);
