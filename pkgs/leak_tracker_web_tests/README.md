# Web tests for leak tracker

This package contains web-platform tests for leak tracker.

The tests are in separate package, because:
1. `flutter test --platform chrome` fails for any test folder except `test`.
2. 'normal' testing for leak tracker uses vm service, that is not available for web.
3. Web testing is not possible with `package:test`, we need `package:flutter_test`,
and there are complications because it depends on concrete version of leak_tracker_flutter_testing.

Command to run tests:

```
flutter test --platform chrome
```
