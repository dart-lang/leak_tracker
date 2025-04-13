
[![CI](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml/badge.svg)](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml)

# Memory leak_tracker

This is a framework for detecting and troubleshooting memory issues in Dart and Flutter applications.

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

## Contributing

For general contributing information, see Dart-wide [CONTRIBUTING.md](https://github.com/dart-lang/.github/blob/main/CONTRIBUTING.md).

For package-specific contributing guidance see:

* [Leak tracking](doc/leak_tracking/CONTRIBUTING.md)
* [Memory usage](doc/USAGE.md#contributing)
