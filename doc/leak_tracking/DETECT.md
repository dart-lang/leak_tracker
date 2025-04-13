
Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Detect Memory Leaks

The documentation below is valid for Flutter SDKs >= 3.18.0.

This page describes how to auto-detect not disposed and not GCed objects.
Read more about leak tracking in [overview](OVERVIEW.md).

## Test cover with `testWidgets`

The Flutter test method `testWidgets` can be configured to track and detect leaks
from all instrumented classes. To enable leak tracking for your entire test suite
and to configure leak tracking settings:

1. Add dev_dependency on `leak_tracker_flutter_testing`. Put `any` instead of version, because
the version is defined by your Flutter SDK.

```yaml
dev_dependencies:
  ...
  leak_tracker_flutter_testing: any
```

2. Add or modify your
[`test/flutter_test_config.dart`](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
file:

```dart
import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

...

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
    .withIgnored(createdByTestHelpers: true);

  ...

  await testMain();
}
```

You can also adjust leak tracking settings for individual tests:

```dart
testWidgets('Images are rendered as expected.',
// TODO(polina-c): make sure images are disposed, https://github.com/polina-c/my_repo/issues/141
experimentalLeakTesting: LeakTesting.settings.withIgnored(classes: ['Image']),
(WidgetTester tester) async {
  ...
```

See documentation for [`testWidgets`](https://github.com/flutter/flutter/blob/4570d35d49477a53278e648ce59a26a06201ec97/packages/flutter_test/lib/src/widget_tester.dart#L122)
for more information.

## Instrument more disposables

To instrument a disposable class for leak tracking, you need to report
object creation and disposal events.

### Instrument objects in Flutter packages

For objects in Flutter packages you may take advantage of the class `FlutterMemoryAllocations`.

To do this, create helper methods, specific to your package,
similar to [what is created in Flutter Framework](https://github.com/flutter/flutter/blob/110b07835ab17e6aea29c6d192649b6fa48e4092/packages/flutter/lib/src/foundation/debug.dart#L149).

Invoke the helpers [in constructor](https://github.com/flutter/flutter/blob/a7f820163c5d7d5321872c60f22fa047fb94bd7b/packages/flutter/lib/src/animation/animation_controller.dart#L256) and [in `dispose`](https://github.com/flutter/flutter/blob/a7f820163c5d7d5321872c60f22fa047fb94bd7b/packages/flutter/lib/src/animation/animation_controller.dart#L932).

### Instrument objects in Dart packages

To instrument objects in pure dart packages, you need to use leak_tracker directly:

```dart
import 'package:new_leak_tracker/leak_tracker.dart';

const library = 'package:my_package/lib/src/my_lib.dart';

class InstrumentedDisposable {
  InstrumentedDisposable() {
    LeakTracking.dispatchObjectCreated(
      library: library,
      className: 'InstrumentedDisposable',
      object: this,
    );
  }

  void dispose() {
    LeakTracking.dispatchObjectDisposed(object: this);
  }
}
```

## See leaks in a running application (experimental)

1. Add [leak_tracker](https://pub.dev/packages/leak_tracker) to `dependencies` in `pubspec.yaml`.

2. Before `runApp` invocation, enable leak tracking

3. For Flutter applications, connect to
the Flutter memory allocation events:

  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:leak_tracker/leak_tracker.dart';

  ...

  void main() {
    FlutterMemoryAllocations.instance.addListener(
      (ObjectEvent event) => LeakTracking.dispatchObjectEvent(event.toMap()),
    );
    LeakTracking.start();
    runApp(...);
  }

  ```

3. Run the application in debug mode and watch for a leak related warnings, like this:

  ```
  leak_tracker: 134 memory leak(s): not disposed: 134, not GCed: 0, GCed late: 0
  ```

4. (optional) To verify leaks are actually being detecting, add leaks:

    a. **not-disposed** Add `FocusNode();` (or any Flutter disposable)
    to a build method. After build method is executed, and some number of GC cycles
    have passed, you will see the the detected leak.

    b. **not-GCed** At `main` of application, after start of leak tracking,
    create and dispose any Flutter disposable (for example
    `FocusNode`), and store the instance in a global array.

    To track notGCed leaks, you

5. Troubleshooting tips:

  a. Get the details of the leaks by collecting them
  on a button click or on some other event. Then either
  analyze the leaks programmatically or print them to the console:

    ```
    final leaks = await LeakTracking.collectLeaks();
    print(leaks.toYaml(phasesAreTests: false));
    ```

  b. To declare all not disposed objects as leaks, invoke `LeakTracking.declareNotDisposedObjectsAsLeaks()`

  c. To add debugging information to an object's record, invoke
  `LeakTracking.dispatchObjectTrace(theObject, <some debugging information>)`

## Limitations

### By environment

Leak tracking is supported only for unit tests within Flutter packages.

It is enabled experimentally for:

1. Web platform
2. Running applications
3. Pure Dart packages

### By leak types

Leak tracking for not-GCed leaks is experimental and is off by default.
At this time, it is recommended to track only not-disposed leaks.

### By tracked classes

The leak_tracker will catch leaks only for instrumented
objects (see [concepts](CONCEPTS.md) for details).

However, the good news is:

1. Disposables in the Flutter Framework are instrumented.
If your Flutter app uses widgets in a way that results in leaks,
`leak_tracker` will catch them.

2. If a leak involves at least one instrumented object,
the leak will be caught and all
other objects, even non-instrumented, will stop leaking as well.

### By build mode

The leak_tracker availability differs by build modes.
See [Dart build modes](https://github.com/dart-lang/site-www/issues/4436)
or [Flutter build modes](https://docs.flutter.dev/testing/build-modes).

**Dart development and Flutter debug**

Leak tracking is fully available.

**Flutter profile**

Leak tracking is available, but `FlutterMemoryAllocations` that listens to
Flutter instrumented objects,
should be [turned on](https://github.com/flutter/flutter/blob/a7f820163c5d7d5321872c60f22fa047fb94bd7b/packages/flutter/lib/src/foundation/memory_allocations.dart#L13)
if you want to track Flutter Framework objects.

**Dart production and Flutter release**

Leak tracking is disabled.

NOTE: If you are interested in enabling leak tracking for release mode, please, comment [here](https://github.com/dart-lang/leak_tracker/issues/25).

## Performance impact

### Memory

The leak_tracker stores a small additional record for each
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
