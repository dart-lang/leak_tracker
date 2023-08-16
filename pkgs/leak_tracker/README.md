[![pub package](https://img.shields.io/pub/v/leak_tracker.svg)](https://pub.dev/packages/leak_tracker)
[![package publisher](https://img.shields.io/pub/publisher/leak_tracker.svg)](https://pub.dev/packages/leak_tracker/publisher)

Coming soon! See https://github.com/flutter/devtools/issues/3951 and https://github.com/flutter/devtools/issues/5606.

## What is this?

This is a framework for detecting memory issues in Dart and Flutter applications.

It enables:

1. [Memory leak auto-detection](https://github.com/dart-lang/leak_tracker/blob/main/doc/DETECT.md) for applications and tests.
2. [Memory usage tracking and auto-snapshotting](https://github.com/dart-lang/leak_tracker/blob/main/doc/USAGE.md).

## Usage

### Leak tracking

First, [understand leak tracking concepts](https://github.com/dart-lang/leak_tracker/blob/main/doc/CONCEPTS.md).

TODO(polina-c): add usage information.

See the [the guidance](https://github.com/dart-lang/leak_tracker/blob/main/doc/TROUBLESHOOT.md) to troubleshoot memory leaks.

### Memory usage tracking

Use the function `trackMemoryUsage` to configure usage events and auto-snapshotting
in your Dart or Flutter application.

See
[usage tracking guidance](https://github.com/dart-lang/leak_tracker/blob/main/doc/USAGE.md)
for more details.
