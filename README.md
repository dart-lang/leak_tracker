
[![CI](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml/badge.svg)](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml)

# Memory Leak Tracker

This is a framework for detecting memory issues in Dart and Flutter applications.

## Packages

| Package | Description | Version |
| --- | --- | --- |
| [leak_tracker](pkgs/leak_tracker/) | (work in progress, used by flutter_test) A framework for memory leak tracking for Dart and Flutter applications. | [![pub package](https://img.shields.io/pub/v/leak_tracker.svg)](https://pub.dev/packages/leak_tracker) |
| [leak_tracker_testing](pkgs/leak_tracker_testing/) | (work in progress, used by flutter_test) Leak tracking code intended for usage in tests. | [![pub package](https://img.shields.io/pub/v/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing) |
| [leak_tracker_flutter_testing](pkgs/leak_tracker_flutter_testing/) | An internal package to test leak tracking with Flutter. | [![pub package](https://img.shields.io/pub/v/leak_tracker_flutter_testing.svg)](https://pub.dev/packages/leak_tracker_flutter_testing) |
| [memory_usage](pkgs/memory_usage/) | (experimental) A framework for memory usage tracking and snapshotting. | [![pub package](https://img.shields.io/pub/v/memory_usage.svg)](https://pub.dev/packages/memory_usage) |

## Guidance

Ready for use:

- [Memory usage](doc/USAGE.md)

Under construction:

- [Memory leak tracking](doc/leak_tracking/OVERVIEW.md)
- [Memory baselining](doc/BASELINE.md)

## Roadmap

Check [Work in progress](https://github.com/dart-lang/leak_tracker/labels/P1) to see what is under construction.

Help us to prioritize future work by upvoting and commenting [potential new features](https://github.com/dart-lang/leak_tracker/labels/P2).

## Contributing

For general contributing information, see Dart-wide [CONTRIBUTING.md](https://github.com/dart-lang/.github/blob/main/CONTRIBUTING.md).

### How to roll the latest version of this package to the Dart SDK repo

To upgrade Dart SDK with new version of `memory_usage` update leak_tracker commit
hash for leak_tracker_rev in [Dart SDK DEPS](https://github.com/dart-lang/sdk/blob/main/DEPS).

### How to roll the latest version of this package to Flutter

To upgrade versions of leak_tracker and/or leak_tracker_testing used by `testWidgets`:

1. Publish new version of the packages.

2. Ask a googler to refresh the packages with copybara in G3.

3. Upgrade [Flutter](https://github.com/flutter/flutter):

    Update versions of leak_tracker and/or leak_tracker_testing in the files:

    - packages/flutter/pubspec.yaml
    - packages/flutter_test/pubspec.yaml
    - packages/flutter_tools/lib/src/commands/update_packages.dart

### How to regenerate DEPENDENCIES.md

To regenerate [diagrams](https://pub.dev/packages/layerlens), run in the root of packages:

```shell
dart run layerlens
```
