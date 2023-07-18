Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Troubleshoot memory leaks

This page describes how to troubleshoot memory leaks. See other information on memory leaks [here](../README.md).

If leak tracker detected a leak in your application or test, first check if the leak matches a [known simple case](#known-simple-cases), and, if no,
switch to [more complicated troubleshooting](#more-complicated-cases).

## Check known simple cases

### 1. The test holds a disposed object

TODO: add example and steps.

## Collect additional information

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

For collecting debugging information in tests, temporarily pass an instance of `LeakTrackingTestConfig` to the test:

```
  testWidgets('My test', (WidgetTester tester) async {
    ...
  }, leakTrackingTestConfig: LeakTrackingTestConfig.debug());
```

Or, you can temporarily set global flag, to make all tests collecting debug information:

```
setUpAll(() {
  LeakTrackerGlobalFlags.collectDebugInformationForLeaks = true;
});
```

**Applications**

For collecting debugging information in your running application, the options are:

1. Pass `LeakTrackingConfiguration` to `enableLeakTracking`
2. Use the interactive UI in DevTools > Memory > Leaks

TODO: link DevTools documentation with explanation

## Verify object references

If you expect an object to be not referenced at some point,
but not sure, you can validate it by temporaryly adding assertion.

```
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

## Complicated cases

### 1. Static or global object causes notGCed leaks

If you see notGCed leaks, where the retaining path starts with a global or static variable,
this means that some objects were disposed, but references to them were never released.

In this example, as `disposedD` is not needed any more, it should stop being referenced, together with disposal.
If `A` and `B` are still needed, `B` should assign null to the variable that references `disposedD`.
Otherwise, the reference to the first non-needed object on the path (`staticX`, `A` or `B`) should be released.

```
staticX -> A -> B -> disposedD
```

### 2. More than one closure context

If a method contains more than one closures, they share the context and thus all
instances of the context will be alive while at least one of the closures is alive.

TODO: add example

Such cases are hard to troubleshoot. One way to fix them is to convert all closures,
which reference the leaked type, to named methods.
