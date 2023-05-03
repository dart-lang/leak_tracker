Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Troubleshoot memory leaks

This page describes how to troubleshoot memory leaks. See other information on memory leaks [here](../README.md).

If leak tracker detected a leak in your application or test, first check if the leak matches a [known simple case](#known-simple-cases), and, if no,
switch to [more complicated troubleshooting](#more-complicated-cases).

## Known simple cases

### 1. The test holds a disposed object

TODO: add steps.

## More complicated cases

To understand the root cause of a memory leak, you may want to gather additional information.

- **not-disposed**:

    - **Allocation call-stack** helps to detect
        the owner of the object that is responsible for the object's disposal.

- **not-GCed or GCed-late**:

    - **Allocation and disposal call-stacks**: helps to understand lifecycle of the
        object which may reveal where the object is being held from garbage collection.

    - **Other lifecycle events**: TODO: add content

    - **Retaining path**: shows which objects hold the leaked one from garbage collection.

## Collect stacktrace

By default, the leak tracker does not collect stacktraces, because the collection may
impact performance and memory footprint.

### In tests

Temporarily setup stacktrace collection for your test:

```
  testWidgets('My test', (WidgetTester tester) async {
    ...
  },
  leakTrackingConfig: LeakTrackingTestConfig(
    stackTraceCollectionConfig: StackTraceCollectionConfig(
      classesToCollectStackTraceOnStart: {'MyClass'},
    )
  ));
```

### In applications

There are options to enable stacktrace collection in applications:

1. By passing `stackTraceCollectionConfig` to `enableLeakTracking`.

https://user-images.githubusercontent.com/12115586/208321882-ecb96152-3aa7-4671-800e-f2eb8c18149e.mov

2. Using interactive UI in DevTools > Memory > Leaks.

TODO: link DevTools documentation with explanation

## Check retaining pathes

Open DevTools > Memory > Leaks, wait for not-GCed leaks to be caught,
and click 'Analyze and Download'.

TODO: add details
