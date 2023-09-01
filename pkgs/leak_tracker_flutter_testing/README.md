[![pub package](https://img.shields.io/pub/v/leak_tracker_flutter_testing.svg)](https://pub.dev/packages/leak_tracker_flutter_testing)
[![package publisher](https://img.shields.io/pub/publisher/leak_tracker_flutter_testing.svg)](https://pub.dev/packages/leak_tracker_flutter_testing/publisher)

Coming soon! See https://github.com/flutter/devtools/issues/3951.

## What is leak_tracker_flutter_testing?

leak_tracker_flutter_testing is Flutter specific test helpers for [leak_tracker](https://pub.dev/packages/leak_tracker).

They are separated from [leak_tracker_testing](https://pub.dev/packages/leak_tracker_testing) because the last one is pure Flutter
package and should not reference Flutter Framework.

## How to use the helpers?

To make your widget test fail in case of leaks, use `testWidgetsWithLeakTracking` instead of `testWidgets`:

```dart
testWidgetsWithLeakTracking('not leaking', (widgetTester) async {
    ...
});
```

See more examples in [end_to_end_test.dart](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end).
