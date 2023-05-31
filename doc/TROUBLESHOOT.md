Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Troubleshoot memory leaks

This page describes how to troubleshoot memory leaks. See other information on memory leaks [here](../README.md).

If leak tracker detected a leak in your application or test, first check if the leak matches a [known simple case](#known-simple-cases), and, if no,
switch to [more complicated troubleshooting](#more-complicated-cases).

## Known simple cases

### 1. The test holds a disposed object

TODO: add steps.

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

For tests, temporary pass instanse of `LeakTrackingTestConfig` to the test:

```
  testWidgets('My test', (WidgetTester tester) async {
    ...
  }, leakTrackingConfig: LeakTrackingTestConfig.debug());
```

For application, the options are:

1. Pass `LeakTrackingConfiguration` to `enableLeakTracking`
2. Use interactive UI in DevTools > Memory > Leaks

TODO: link DevTools documentation with explanation

## Known complicated cases

### 1. More than one closure context

If a method contains more than one closures, they share the context and thus all
instances of the context will be alive while at least one of the closures is alive.

TODO: add example

Such cases are hard to troubleshoot. One way to fix them is to convert all closures
that use the leaked type, to named methods.

