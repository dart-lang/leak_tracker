Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Troubleshoot memory leaks

This page describes how to troubleshoot memory leaks.
Read more about leak tracking in [overview](OVERVIEW.md).

If leak_tracker detected a leak in your application or test, first check if the leak matches a [known simple case](#known-simple-cases), and, if no,
switch to [more complicated troubleshooting](#more-complicated-cases).

## General rules

Follow the rules to avoid/fix notGCed and notDisposed leaks:

1. **Ownership**. Every disposable object should have clear owner that manages its lifecycle.
2. **Disposal**. The owner should invoke the object's `dispose`.
3. **Release**. The owner should null reference to the disposed object, if its `dispose` happens earlier than owner's disposal.
4. **Weak referencing**. Non-owners should either link the object with WeakReference, or make sure to
   release the references before the owner disposed the object.

A test specific rule:
1. If your test creates a disposable object, it should dispose it in `tearDown`, so that test failure does not result in a leak:

```dart
final FocusNode focusNode = FocusNode();
addTearDown(focusNode.dispose());
```

## Known simple cases

### 1. The test creates OverlayEntry

If your code creates an OverlayEntry, it should both remove and dispose it:

```dart
final OverlayEntry overlayEntry = OverlayEntry(...);
addTearDown(() => overlayEntry..remove()..dispose());
```

### 2. The test starts a gesture

If your test starts a test gesture, make sure to finish it to release resources:

```dart
final TestGesture gesture = await tester.startGesture(
...
// Finish gesture to release resources.
await tester.pumpAndSettle();
await gesture.up();
await tester.pumpAndSettle();
```

### 3. The test is leaking Image, ImageInfo or ImageStreamCompleterHandle

If your test is creating images that are designed to stay in the cache,
you need to invoke `imageCache.clear()` after the test.

Add it to:
* `tearDownAll` to optimize for testing performance
* `tearDown` to optimize for test isolation

Sometimes `imageCache.clear()` does not dispose images handle, but schedules dispocal
no happen after rendering cyscles completion. 
If this is a case, `imageCache.clear()` needs to happen as last statement of the test,
instead of in tear down, to allow the cycles to happen.

## Get additional information

To understand the root cause of a memory leak, you may want to gather additional information.

- **not-disposed**:

    - **Allocation call-stack** helps to detect
        the owner of the object that is responsible for the object's disposal.

- **not-GCed or GCed-late**:

    - **Allocation and disposal call-stacks**: helps to understand lifecycle of the
        object which may reveal where the object is being held from garbage collection.

    - **Other lifecycle events**: TODO: add content

    - **Retaining path**: shows which objects hold the leaked one from garbage collection.


By default, the leak_tracker does not gather the information, because the collection may
impact performance and memory footprint.

**Tests**

For collecting debugging information in a test, temporarily
specify what information you need in the test settings:

```dart
testWidgets('My test',
experimentalLeakTesting: LeakTesting.settings.withCreationStackTrace(),
(WidgetTester tester) async {
  ...
});
```

**Applications**

TODO: add documentation, https://github.com/dart-lang/leak_tracker/issues/172

## Verify object references

If you expect an object to be not referenced at some point,
but not sure, you can validate it by temporarily adding assertion.

```dart
import 'package:leak_tracker/leak_tracker.dart';

...
final ref = WeakReference(myObject);
myObject = null;
await forceGC();
if (ref.target == null) {
  throw StateError('Validated that myObject is not held from garbage collection.');
} else {
  print(await formattedRetainingPath(ref));
  throw StateError('myObject is reachable from root. See console output for the retaining path.');
}
```

NOTE: this code will not work in release mode, so
you need to run it with flag `--debug` or `--profile`.

## More complicated cases

### 1. It is not clear who owns ChangeNotifier

[ChangeNotifier] is disposable and is tracked by leak_tracker.

But, as it is mixin, it does not have its own constructor. So, it
communicates object creation in first `addListener`, that results
in creation stack trace pointing to `addListener`, not to constructor.

To make debugging easier, invoke [ChangeNotifier.maybeDispatchObjectCreation]
in constructor of the class. It will help
to identify the owner in case of leaks.

Be sure to guard the invocation behind the
[`kFlutterMemoryAllocationsEnabled`](https://api.flutter.dev/flutter/foundation/kFlutterMemoryAllocationsEnabled-constant.html)
flag.
This will ensure the body of `maybeDispatchObjectCreation` is only compiled into your app
if memory allocation events are enabled.

```
if (kFlutterMemoryAllocationsEnabled) {
  maybeDispatchObjectCreation(this);
}
```

### 2. Static or global object causes notGCed leaks

If you see notGCed leaks, where the retaining path starts with global or static variable,
this means that some objects were disposed, but references to them were never released.

```
root -> staticA -> B -> C -> disposedD
```

In this example, `disposedD` should stop being reachable from the root.
You need to find the closest to the root object, that is not needed any more and release
reference to it, that will make
the entire chain after available for garbage collection.

There are ways to release the reference:

1. If the object is disposed by owner in the owner's dispose, check who holds the owner and release the reference to it:

```dart
void dispose() {
  disposedD.dispose();
}
```

2. If the object is disposed earlier than owner's disposal, null the reference out:

```dart
disposedD?.dispose();
disposedD = null;
```

3. If the object is held by non-owner, make the reference weak:

```dart
class C {
  ...
  final WeakReference<MyClass> disposedD;
  ...
}
```

### 2. More than one closure context

If a method contains more than one closures, they share the context and thus all
instances of the context will be alive while at least one of the closures is alive.

TODO: add example (if you have a good example, please, contribute), https://github.com/dart-lang/leak_tracker/issues/207

Such cases are hard to troubleshoot. One way to fix them is to convert all closures,
which reference the leaked type, to named methods.

### 3. Leak is originated in a dependency

If a found leak is originated in the Flutter Framework or a dependent package, file a bug or contribute a fix to the repo.

See the [tracking issue](https://github.com/flutter/flutter/issues/134787) for memory leak clean up in Flutter Framework.
See documentation for [`testWidgets`](https://github.com/flutter/flutter/blob/4570d35d49477a53278e648ce59a26a06201ec97/packages/flutter_test/lib/src/widget_tester.dart#L122)
to learn how to ignore leaks while a fix is on the way.

### 4. Leaking object is Image

Images in Flutter have an unusual lifecycle:

1. Image and ImageInfo have a [non-standard contract for disposal](https://github.com/flutter/flutter/blob/1f64be86810ac4082e250fde8efc6ed212c538e1/packages/flutter/lib/src/painting/image_stream.dart#L18).

2. The setting `.withIgnored(createdByTestHelpers: true)` does not work for images, because
creation of their native part is not detectable as happening in a test helper.

3. Images are cashed and reused that improves test performance. So, `tearDownAll(imageCache.clear)`
will help if leaks are caused by test code. 
