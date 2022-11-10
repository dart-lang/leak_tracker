[![CI](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml/badge.svg)](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml)

# Memory Leak Tracker

This is a framework for memory leak tracking for Dart and Flutter applications.
Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below this sentence is under construction.

## Getting started

In your Flutter application, before `runApp` invocation, enable the leak tracking, and connect the Flutter memory allocation events:

```
enableLeakTracking();
MemoryAllocations.instance
      .addListener((ObjectEvent event) => dispatchObjectEvent(event.toMap()));
```

See more at [Dart memory leak tracker](https://github.com/flutter/devtools/blob/master/packages/devtools_app/lib/src/screens/memory/panes/leaks/LEAK_TRACKING.md).
