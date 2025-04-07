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

## Use different leak tracker

When you reference leak tracker from your application, version should be `any`, because
the version is pinned by Flutter.

If you want to use a different version, you will need to reference a renamed leak tracker package.

To use the latest version of leak tracker locally, if Flutter did not upgrade to it yet:

1. Clone it: `git clone git@github.com:dart-lang/leak_tracker.git`

2. Replace ' leak_tracker' with ' new_leak_tracker' in all files 'pubspec.yaml, pubspec_overrides.yaml':

   ![replace](images/rename.png "Rename leak_tracker")

3. In your project reference leak tracker with path:

   ```
   new_leak_tracker:
     path: <local path to leak tracker>
   ```

4. Follow steps in
