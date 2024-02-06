## 3.0.1-wip

* Fixed typo by renaming `experimantalAllNotGCed` to `experimentalAllNotGCed`.

## 3.0.0

* Rename `IgnoredLeaks.notGCed` to `IgnoredLeaks.experimentalNotGCed`
and make notGCed leaks ignored by leak tracking tests by default.

## 2.0.3

* Require Dart SDK 3.2.0 or later.

## 2.0.2

* Allow to ignore objects created by test helpers.
* Set `ignore = false` by default.

## 2.0.1

* Add LeakTesting.enabled.

## 2.0.0

* Remove fields `failOnLeaksCollected` and `onLeaks` from `LeakTesting`.

## 1.0.6

* Updated to use `package:lints/recommended.yaml` for analysis.
* Move LeakTesting from leak_tracker to this library.

## 1.0.5

* Stop depending on test.

## 1.0.4

* Bump version of SDK to 3.1.2.

## 1.0.3

* Update version of leak_tracker to `^9.0.0`.

## 1.0.2

* Update version of leak_tracker to `^8.0.0`.
* Set version of leak_tracker to `any`.

## 1.0.0

* Create version.
