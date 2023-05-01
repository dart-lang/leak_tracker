Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

TODO: separate information for tests and applications.

# Troubleshoot Memory Leaks

This page describes how to troubleshoot memory leaks. See other information on memory leaks [here](../README.md).

To understand root cause of a memroy leak, gather additional information.

For non

## Collect callstack

Stacktrace for the object's lifecycle events may help to catch out
the leak's root cause. The lifecycle event will be creation
for not-disposed leaks, and disposal for non-GCed leaks.

By default, the leak tracker does not collect stacktraces, because the collection may
impact performance and memory footprint.

There are options to enable stacktrace collection
for troubleshooting:

1. By passing `stackTraceCollectionConfig`
to `withLeakTracking` or `enableLeakTracking`.

https://user-images.githubusercontent.com/12115586/208321882-ecb96152-3aa7-4671-800e-f2eb8c18149e.mov

2. Using interactive UI in DevTools > Memory > Leaks.

TODO: link DevTools documentation with explanation

## Check retaining pathes

Open DevTools > Memory > Leaks, wait for not-GCed leaks to be caught,
and click 'Analyze and Download'.

TODO: add details
