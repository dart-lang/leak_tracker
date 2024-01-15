
Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Detect Memory Leaks

This page describes how to auto-detect certain types of memory leaks.
Read more about leak tracking in [overview](OVERVIEW.md).

## Quick start to track leaks for Flutter

### Test cover with `testWidgets`

To make `testWidgets` detecting leaks in your tests, enable leak tracking in [`test/flutter_test_config.dart`](see hhttps://api.flutter.dev/flutter/flutter_test/flutter_test-library.html):

```dart
import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

...

FutureOr<void> testExecutable(FutureOr<void> Function() testMain) {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
    .withIgnored(createdByTestHelpers: true);

  ...

  return testMain();
}
```

See [documentation for `testWidgets`](https://github.com/flutter/flutter/blob/4570d35d49477a53278e648ce59a26a06201ec97/packages/flutter_test/lib/src/widget_tester.dart#L122) on how to adjust leak tracking settings.

### Instrument more disposables

Use [this example](https://github.com/flutter/flutter/pull/138804/files) to add your disposables to leak tracking.

### See leaks in a running Flutter application

TODO(polina-c): implement and test this scenario

1. Add [leak_tracker](https://pub.dev/packages/leak_tracker) to `dependencies` in `pubspec.yaml`.

2. Before `runApp` invocation, enable leak tracking, and connect
the Flutter memory allocation events:

```dart
import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

...

enableLeakTracking();
FlutterMemoryAllocations.instance
      .addListener((ObjectEvent event) => dispatchObjectEvent(event.toMap()));
runApp(...

```

3. Run the application in debug mode and watch for a leak related warnings.

TODO(polina-c): add example of the warning.

## Limitations

### By environment

Leak tracker is enabled for unit tests in Flutter packages.

Current version of leak tracker is off for:

1. Web platform
2. Running applications
3. Pure Dart packages

### By leak types

Leak tracking for not-GCed leaks is experimental and is off by default.
For now it is recommended to track only not-disposed leaks.

### By tracked classes

The leak tracker will catch leaks only for instrumented
objects (See [concepts](CONCEPTS.md) for details).

However, the good news is:

1. Disposables in Flutter Framework are instrumented.
If how your Flutter app manages widgets results in leaks,
Flutter will catch them.

2. If a leak involves at least one instrumented object,
the leak will be caught and all
other objects, even non-instrumented, will stop leaking as well.

See [the instrumentation guidance](#instrument-your-code).

### By build mode

The leak tracker availability differs by build modes.
See [Dart build modes](https://github.com/dart-lang/site-www/issues/4436)
or [Flutter build modes](https://docs.flutter.dev/testing/build-modes).

**Dart development and Flutter debug**

Leak tracking is fully available.

**Flutter profile**

Leak tracking is available, but FlutterMemoryAllocations that listens to
Flutter instrumented objects,
should be [turned on](https://github.com/flutter/flutter/blob/15af81782e19ebe7273872f8b07ac71df4e749f2/packages/flutter/lib/src/foundation/memory_allocations.dart#L13)
if you want to track Flutter Framework objects.

**Dart production and Flutter release**

Leak tracking is disabled.

NOTE: If you are interested in enabling leak tracking for release mode, please, comment [here](https://github.com/dart-lang/leak_tracker/issues/25).

## Performance impact

### Memory

The Leak Tracker stores a small additional record for each
tracked alive object and for each
detected leak, that increases the memory footprint.

For the [Gallery application](https://github.com/flutter/gallery)
in profile mode on `macos`
the leak tracking increased memory footprint of the home page
by ~400 KB that is ~0.5% of
the total.

### CPU

Leak tracking impacts CPU in two areas:

1. Per object tracking.
   Added ~0.05 of millisecond (~2.7%) to the total load time of
   [Gallery](https://github.com/flutter/gallery) home page
   in profile mode on `macos`.

2. Regular asynchronous analysis of the tracked objects.
   Took ~2.5 milliseconds for
   [Gallery](https://github.com/flutter/gallery) home page in
   profile mode on `macos`.
