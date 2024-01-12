
Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Detect Memory Leaks

This page describes how to auto-detect certain types of memory leaks in Dart and Flutter applications and tests.
Read more about leak tracking in [overview](OVERVIEW.md).

## Quick start to track leaks for Flutter

### Flutter application

1. Add [leak_tracker](https://pub.dev/packages/leak_tracker) to `dependencies` in `pubspec.yaml`.

2. Before `runApp` invocation, enable leak tracking, and connect
the Flutter memory allocation events:

```dart
import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

...

enableLeakTracking();
MemoryAllocations.instance
      .addListener((ObjectEvent event) => dispatchObjectEvent(event.toMap()));
runApp(...

```

3. Run the application in debug mode and watch for a leak related warnings.
If you see a warning, open the link to investigate the leaks.

TODO(polina-c): implement the link and add example of the warning.

### Flutter tests

Wrap your tests with `withLeakTracking` to setup automated leak verification:

```dart
test('...', () async {
  final leaks = await withLeakTracking(
    () async {
      ...
    },
  );

  expect(leaks, leakFree);
});
```


## Limitations

### By platform

Leak tracker does not work for web platform.

### By tracked classes

The leak tracker will catch leaks only for instrumented
objects (See [concepts](CONCEPTS.md) for details).

However, the good news is:

1. Most disposable Flutter Framework classes include instrumentation.
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

Leak tracking is available, but MemoryAllocations that listens to
Flutter instrumented objects,
should be [turned on](https://github.com/flutter/flutter/blob/15af81782e19ebe7273872f8b07ac71df4e749f2/packages/flutter/lib/src/foundation/memory_allocations.dart#L13)
if you want to track Flutter Framework objects.

**Dart production and Flutter release**

Leak tracking is disabled.

NOTE: If you are interested in enabling leak tracking for release mode, please, comment [here](https://github.com/dart-lang/leak_tracker/issues/25).

## Instrument your code

If you want to catch leaks for objects outside of Flutter Framework
(that are already instrumented), you need to instrument them.

For each tracked object the library should get two signals from your code:
(1) the object is created and (2) the object is not in use.
It is most convenient to give the first signal in the constructor
and the second signal in the `dispose` method:

```dart
import 'package:leak_tracker/src/leak_tracker.dart';

class InstrumentedClass {
  InstrumentedClass() {
    dispatchObjectCreated(
      library: library,
      className: '$InstrumentedClass',
      object: this,
    );
  }

  static const library = 'package:my_package/lib/src/my_lib.dart';

  void dispose() {
    dispatchObjectDisposed(object: this);
  }
}
```

## Start/stop leak tracking

To start leak tracking, invoke `enableLeakTracking()`,
to stop: `disableLeakTracking()`.

TODO(polina-c): note that Flutter Framework enables leak tracking by default,
when it is the case.

## Collect leaks

There are two steps in leak collection: (1) get signal that leaks happened
(leak summary) and (2) get details about the leaks.

By default, the leak tracker checks for leaks every second, and,
if there are some, outputs the
summary to console and sends it to DevTools. Then you can get
leak details either by
requesting them from DevTools or by invoking `collectLeaks()`
programmatically.

You can change the default behavior by passing customized
[configuration](https://github.com/dart-lang/leak_tracker/blob/29fa7c0e7fb950c974d15f838636bc97a03a5bcc/lib/src/leak_tracker_model.dart)
to `enableLeakTracking()`:

1. Disable regular leak checking and check the leaks by calling `checkLeaks()`.
2. Disable output to console or to DevTools.
3. Listen to the leaks with custom handler.

See `DevTools > Memory > Leaks` guidance on how to interact with leak tracker.

TODO: add link to DevTools documentation.

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
