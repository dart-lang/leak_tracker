Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Troubleshoot memory leaks

This page describes how to troubleshoot memory leaks. See other information on memory leaks [here](../README.md).

If leak tracker detected a leak in your application or test, first check if the leak matches a [known simple case](#known-simple-cases), and, if no,
switch to [more complicated troubleshooting](#more-complicated-cases).

## General rules

Follow the rules to avoid/fix notGCed and notDisposed leaks:

1. **Ownership**. Every disposable object should have clear owner that manages its lifecycle.
2. **Disposal**. The owner should invoke the object's `dispose`.
3. **Release**. The owner should null referernce to the disposed object, if its `dispose` happens earlier than owner's disposal.
4. **Weak referencing**. Non-owners should either link the object with WeakReference, or make sure to
   release the references before the owner disposed the object.

A test specific rule:
1. If your test creates a disposable object, it should dispose it in `tearDown`, so that test failure does not result in a leak:

```dart
final FocusNode focusNode1 = FocusNode(debugLabel: 'IconButton 1');
final FocusNode focusNode2 = FocusNode(debugLabel: 'IconButton 2');
addTearDown(() {  focusNode1.dispose();  focusNode2.dispose();});
```

## Known simple cases

### 1. The test holds a disposed object

TODO: add example and steps.

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


By default, the leak tracker does not gather the information, because the collection may
impact performance and memory footprint.

**Tests**

For collecting debugging information in tests, temporarily pass an instance of `LeakTrackingTestConfig`,
specific for the debugged leak type, to the test:

```dart
testWidgetsWithLeakTracking('My test', (WidgetTester tester) async {
  ...
}, leakTrackingTestConfig: LeakTrackingTestConfig.debugNotGCed());
```

**Applications**

For collecting debugging information in your running application, the options are:

1. Pass `LeakTrackingConfiguration` to `enableLeakTracking`
2. Use the interactive UI in DevTools > Memory > Leaks

TODO: link DevTools documentation with explanation

## Verify object references

If you expect an object to be not referenced at some point,
but not sure, you can validate it by temporaryly adding assertion.

```dart
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

IMPORTANT: this code will not work in release mode, so
you need to run it with flag `--debug` or `--profile`
([not available](https://github.com/flutter/flutter/issues/127331) for Flutter tests),
or, if it is a test, by clicking `Debug` near the test name in IDE.

## More complicated cases

### 1. It is not clear who owns ChangeNotifier

[ChangeNotifier] is disposable and is tracked by leak_tracker.

But, as it is mixin, it does not have its own constructor. So, it
communicates object creation in first `addListener`, that results
in creation stack trace pointing to `addListener`, not to constructor.

To make debugging easier, invoke [ChangeNotifier.maybeDispatchObjectCreation]
in constructor of the class. It will help
to identify the owner in case of leaks.

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

TODO: add example

Such cases are hard to troubleshoot. One way to fix them is to convert all closures,
which reference the leaked type, to named methods.
