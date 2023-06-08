
Coming soon! See https://github.com/flutter/devtools/issues/3951 and https://github.com/flutter/devtools/issues/5606.

The text below is under construction.

[![CI](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml/badge.svg)](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml)

# Memory Leak Tracker

TODO: replace links with absolute, to make them working on pub.dev

This is a framework for detecting memory issues in Dart and Flutter applications. It enables:

1. [Memory leak auto-detection](doc/DETECT.md) for applications and tests.
2. [Memory usage tracking and auto-snapshotting](doc/USAGE.md).

Documentation:
1. [Understand leak tracking concepts](doc/CONCEPTS.md)
2. [Troubleshoot memory leaks](doc/TROUBLESHOOT.md)

## Packages

| Package | Description | Version |
| --- | --- | --- |
| [leak_tracker](pkgs/leak_tracker/) | A framework for memory leak tracking for Dart and Flutter applications. | [![pub package](https://img.shields.io/pub/v/leak_tracker.svg)](https://pub.dev/packages/leak_tracker) |
| [leak_tracker_flutter_test](pkgs/leak_tracker_flutter_test/) | Tests for leak_tracker that depend on Flutter framework. |  |
| [leak_tracker_testing](pkgs/leak_tracker_testing/) | Leak tracking code intended for usage in tests. | [![pub package](https://img.shields.io/pub/v/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing) |
