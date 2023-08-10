[![pub package](https://img.shields.io/pub/v/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing)
[![package publisher](https://img.shields.io/pub/publisher/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing/publisher)

Coming soon! See https://github.com/flutter/devtools/issues/3951.

## What is this?

This is test helpers for [leak_tracker](https://pub.dev/packages/leak_tracker).

They are separated from `leak_tracker` to make sure
testing code is not used in production.

## How to use the helpers?

To make your test failing in case of leaks with descriptive message, pass the instance of 'Leaks' to the matcher `isLeakFree`:

```
final leaks = await LeakTracking.collectLeaks();
expect(leaks, isLeakFree);
```

See more examples in [end_to_end_test.dart](https://github.com/dart-lang/leak_tracker/blob/main/pkgs/leak_tracker/test/tests/leak_tracking/end_to_end_test.dart).
