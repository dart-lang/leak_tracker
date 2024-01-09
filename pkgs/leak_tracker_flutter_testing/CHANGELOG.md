## 2.0.1

* Upgrade to leak_tracker 10.0.0 and leak_tracker_testing 2.0.1.

## 2.0.0

* Remove declaration of testWidgetsWithLeakTracking.

## 1.0.12

* Update to use `package:lints/recommended.yaml` for analysis.
* Add API to integrate with testWidgets.

## 1.0.10

* Move LeakTesting out of this package to leak_tracker.
* Fix bug in equality for LeakTracking.

## 1.0.9

* Update `testWidgetsWithLeakTracking` to avoid duplicated leak tracking by testWidgets.

## 1.0.8

* Make configuration adjustable.

## 1.0.7

* Set version of leak_tracker_testing to `^1.0.5`.

## 1.0.6

* If an object is not disposed by the end of testing, mark it as notDisposed.

## 1.0.5

* Bump version of SDK to 3.1.2.

## 1.0.4

* Update matcher for memory events to handle async callbacks.

## 1.0.3

* Define matcher to verify if a class is reporting memory allocations.

## 1.0.2

* Add debugging constructors to LeakTrackingTestConfig, per leak type.

## 1.0.1

* Expose global leak tracking settings.

## 1.0.0

* First release.
