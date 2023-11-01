
[![CI](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml/badge.svg)](https://github.com/dart-lang/leak_tracker/actions/workflows/ci.yaml)

# Memory Leak Tracker

This is a framework for detecting memory issues in Dart and Flutter applications.

## Packages

| Package | Description | Version |
| --- | --- | --- |
| [leak_tracker](pkgs/leak_tracker/) | A framework for detecting memory issues for Dart and Flutter applications. | [![pub package](https://img.shields.io/pub/v/leak_tracker.svg)](https://pub.dev/packages/leak_tracker) |
| [leak_tracker_flutter_testing](pkgs/leak_tracker_flutter_testing/) | Leak tracking helpers intended for usage in Flutter tests. | [![pub package](https://img.shields.io/pub/v/leak_tracker_flutter_testing.svg)](https://pub.dev/packages/leak_tracker_flutter_testing) |
| [leak_tracker_testing](pkgs/leak_tracker_testing/) | Leak tracking helpers intended for usage in Dart and Flutter tests. | [![pub package](https://img.shields.io/pub/v/leak_tracker_testing.svg)](https://pub.dev/packages/leak_tracker_testing) |

## Roadmap

Check [Work in progress](https://github.com/dart-lang/leak_tracker/labels/P1) to see what is under construction.

Help us to prioritize future work by upvoting and commenting [potential new features](https://github.com/dart-lang/leak_tracker/labels/P2).

## Contributing

For general contributing information, see Dart-wide [CONTRIBUTING.md](https://github.com/dart-lang/.github/blob/main/CONTRIBUTING.md).

### How to upgrade `testWidgets` with new version of leak_tracker

To upgrade leak_tracker version used by `testWidgets`:

1. Publish new version of leak_tracker and/or leak_tracker_testing.

2. Update leak_tracker commint hash for leak_tracker_rev in [Dart SDK DEPS](https://github.com/dart-lang/sdk/blob/main/DEPS).

3. Upgrade [Flutter](https://github.com/flutter/flutter):

    Update versions of leak_tracker and/or leak_tracker_testing in the files:

    - packages/flutter/pubspec.yaml
    - packages/flutter_test/pubspec.yaml
    - packages/flutter_tools/lib/src/commands/update_packages.dart


### How to regenerate diagrams

To regenerate diagrams, run:

```shell
dart run layerlens
```
