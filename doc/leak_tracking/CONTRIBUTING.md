# Contributing to leak tracker.

For general contributing information, see Dart-wide [CONTRIBUTING.md](https://github.com/dart-lang/.github/blob/main/CONTRIBUTING.md).

##  Roll the latest version of `leak_tracker` to Flutter

To upgrade version of leak tracking packages used by `testWidgets`:

1. Publish new version of the packages.

2. Upgrade [Flutter](https://github.com/flutter/flutter):

    - Update versions of leak_tracker* in [update_packages_pins.dart](https://github.com/flutter/flutter/blob/main/packages/flutter_tools/lib/src/update_packages_pins.dart)
    - In flutter package run `../../bin/flutter update-packages --force-upgrade`

## Regenerate DEPENDENCIES.md

To regenerate [diagrams](https://pub.dev/packages/layerlens), run in the root of packages:

```shell
sh tool/diagrams.sh
```

