[![pub package](https://img.shields.io/pub/v/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing)
[![package publisher](https://img.shields.io/pub/publisher/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing/publisher)

Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

## What is this?

This is Flutter specific test helpers for [leak_tracker](https://pub.dev/packages/leak_tracker).

## How to use the helpers?

To make your widget test failing in case of leaks, use `testWidgetsWithLeakTracking` instead of `testWidgets`:

```
testWidgetsWithLeakTracking('not leaking', (widgetTester) async {
    ...
});
```

See more examples in [end_to_end_test.dart](https://github.com/dart-lang/leak_tracker/tree/main/pkgs/leak_tracker_flutter_testing/test/tests/end_to_end).
