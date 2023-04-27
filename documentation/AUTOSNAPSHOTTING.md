Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Auto Snapshotting

Dart and Flutter applications can be confugured to automatically save
memory heap snapshots to hard drive, in case of memory overuse.
The snapshots can be later analysed in DevTools.

TODO (polina-c): add link to DEvTools help section.

## Configure auto-snapshotting

Use the function `autoSnapshotOnMemoryOveruse` to configure auto-snapshotting. We
recommend to have autosnapshotting off by default, with possibility
to enable it via command line arguments in case of memory issues.

See [example](../more_examples/autosnapshotting/).


## Limitations

**Enabled for:** Flutter
debug and profile modes (that are Dart debug and release modes).
**Disabled for:** Flutter release mode (that is Dart product mode).

See [Dart build modes](https://github.com/dart-lang/site-www/issues/4436)
or [Flutter build modes](https://docs.flutter.dev/testing/build-modes).
