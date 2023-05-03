Coming soon! See https://github.com/flutter/devtools/issues/5606.

The text below is under construction.

# Auto-Snapshot Memory Heap

This page describes how to configure Dart heap auto-snapshotting. See other information on memory leaks [here](../README.md).

Dart and Flutter applications can be confugured to automatically save
memory heap snapshots to hard drive, in case of memory overuse.
The snapshots can be later analysed in DevTools.

TODO (polina-c): add link to DEvTools help section.

https://user-images.githubusercontent.com/12115586/234953319-6f864d25-9854-4126-b4d6-8e114b9045ff.mov

## Configure auto-snapshotting

Use the function `autoSnapshotOnMemoryOveruse` to configure auto-snapshotting. We
recommend to have autosnapshotting off by default, with possibility
to enable it via command line arguments in case of memory issues.

See [example](../more_examples/autosnapshotting/).

## Limitations

* **Enabled for:** Flutter debug and profile modes (equivalent to Dart debug and release modes).
* **Disabled for:** Flutter release mode (equivalent to Dart product mode).

See [Dart build modes](https://github.com/dart-lang/site-www/issues/4436)
or [Flutter build modes](https://docs.flutter.dev/testing/build-modes).
