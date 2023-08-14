
[![CI](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml/badge.svg)](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml)

# Memory Leak Tracker

This is a framework for detecting memory issues in Dart and Flutter applications.

## Packages

| Package | Description | Version |
| --- | --- | --- |
| [leak_tracker](pkgs/leak_tracker/) | A framework for detecting memory issues for Dart and Flutter applications. | [![pub package](https://img.shields.io/pub/v/leak_tracker.svg)](https://pub.dev/packages/leak_tracker) |
| [leak_tracker_flutter_testing](pkgs/leak_tracker_flutter_testing/) | Leak tracking helpers intended for usage in Flutter tests. | [![pub package](https://img.shields.io/pub/v/leak_tracker_flutter_testing.svg)](https://pub.dev/packages/leak_tracker_flutter_testing) |
| [leak_tracker_testing](pkgs/leak_tracker_testing/) | Leak tracking helpers intended for usage in tests. | [![pub package](https://img.shields.io/pub/v/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing) |

## Features

[Work in progress](https://github.com/dart-lang/leak_tracker/labels/P1)
[Upvote and comment, to help with prioritization](https://github.com/dart-lang/leak_tracker/labels/P2)

## Contribution notes

### How to enable logs

To temporary enable logs, add this line to `main`:

```
Logger.root.onRecord.listen((LogRecord record) => print(record.message));
```

### How to regenerate diagrams

To regenerate diagrams, run:

```
dart run layerlens
```
