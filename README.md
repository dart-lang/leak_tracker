[![CI](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml/badge.svg)](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml)

# Memory Leak Tracker

This is a framework for memory leak tracking for Dart and Flutter applications.

Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below this sentence is under construction.

## Getting started

To track memory leaks in your Flutter application:

1. Before `runApp` invocation, enable leak tracking, and connect the Flutter memory allocation events:

```dart
import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

...

enableLeakTracking();
MemoryAllocations.instance
      .addListener((ObjectEvent event) => dispatchObjectEvent(event.toMap()));
runApp(...

```

2. Run application in debug mode and watch for a leak related warnings. If you see a warning, click the provided link to investigate the leaks.

TODO(polina-c): add example of the warning

See more on memory leaks and leak tracking at [Dart memory leak tracker](https://github.com/flutter/devtools/blob/master/packages/devtools_app/lib/src/screens/memory/panes/leaks/LEAK_TRACKING.md).
