[![pub package](https://img.shields.io/pub/v/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing)
[![package publisher](https://img.shields.io/pub/publisher/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing/publisher)

Coming soon! See https://github.com/flutter/devtools/issues/3951.

## What is this?

This is helper for testing [leak_tracker](https://pub.dev/packages/leak_tracker).

They are separated from `leak_tracker` to make sure
testing code is not used in production.

## How to use the helpers?

To test for leaks with descriptive messages, use `isLeakFree` against a `Leaks` instance:

```dart
final leaks = await LeakTracking.collectLeaks();
expect(leaks, isLeakFree);
```

See more examples in [end_to_end_test.dart](https://github.com/dart-lang/leak_tracker/blob/main/pkgs/leak_tracker/test/tests/leak_tracking/end_to_end_test.dart).
