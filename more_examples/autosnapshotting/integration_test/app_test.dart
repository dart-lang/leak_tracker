import 'package:autosnapshotting/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Run:
// flutter test integration_test/app_test.dart -d macos

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on the floating action button, verify counter',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.textContaining('RSS'), findsOneWidget);

      await tester.tap(find.byTooltip('Allocate more memory'));

      await tester.pumpAndSettle();
    });
  });
}
