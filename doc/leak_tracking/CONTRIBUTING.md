# Contributing to leak tracker.

For general contributing information, see Dart-wide [CONTRIBUTING.md](https://github.com/dart-lang/.github/blob/main/CONTRIBUTING.md).

### How to roll the latest version of `leak_tracker` to Flutter

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
sh tool/diagrams.sh
```

