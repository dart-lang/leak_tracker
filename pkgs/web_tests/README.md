This package contains tests that need 'flutter_test' to run.

The tests are in separate separated package:
1. To avoid cycle dependencies between flutter_test and leak_tracker_flutter_testing.
2. Because `flutter test --platform chrome` fails for any test folder except `web`.
