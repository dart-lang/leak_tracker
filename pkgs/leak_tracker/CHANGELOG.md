# 10.0.4

* Add exceptions to test helpers.

# 10.0.3

* Improve performance of the case with ignored test helpers.

# 10.0.2

* Require Dart SDK 3.2.0 or later.

# 10.0.1

* Allow to ignore objects created by test helpers.

## 10.0.0

* Remove `memory_usage`, as it is moved to https://github.com/dart-lang/leak_tracker/tree/main/pkgs/memory_usage.

## 9.0.18

* Update `vm_service` dependency to `>=11.0.0 <15.0.0`.

## 9.0.17

* Move LeakTesting to leak_tracker_testing.

## 9.0.16

* Stub web implementation for retaining path to serve G3.

## 9.0.15

* Fix: debug information should not wipe other settings.
* Add arguments allNotGCed and allNotDisposed to withTracked.
* Remove the dependency on `package:intl`.
* Updated to use `package:lints/recommended.yaml` for analysis.

## 9.0.14

* Remove the dependency on `package:web_socket_channel`.

## 9.0.13

* Define `LeakTesting`.

## 9.0.12

* Update `vm_service` dependency to `>=11.0.0 <14.0.0`.

## 9.0.11

* Remove dependency on logging.
* Avoid double leak tracking.

## 9.0.10

* Use `IgnoredLeaks`.

## 9.0.9

* Define `IgnoredLeaks`.
* Add item `none` to BaseliningMode.

## 9.0.8

* Enable declaring all not disposed objects as leaks.

## 9.0.7

* Use ObjectRecord instead of hash code to identify objects.
* Remove collection of stack trace by class in LeakDiagnosticConfig.
* Bump version of SDK to 3.1.2.

## 9.0.6

* Improve error reporting for connection to vm service.
* Fix misspelling.
* Enable memory baselining.

## 9.0.5

* Fix issue of using wrong settings for a phase, so that the tracker uses settings
at time of object tracking start, instead of current configuration.

## 9.0.4

* Make it possible to disable tracking for a type of leak.

## 9.0.3

* Stop failing if an object is disposed twice.

## 9.0.2

* Make sure phase boundaries are handled correctly.

## 9.0.1

* Auto-start VM Service when needed.

## 9.0.0

* Refactor to improve performance of regression tests with leak tracking.
* Remove API that is not used in Flutter Framework.
* Rename `LeakTrackingConfiguration` to `LeakTrackingConfig`.
* Remove global flag [collectDebugInformationForLeaks].
* Rename `checkNonGCed` to `checkNotGCed` and `collectRetainingPathForNonGCed` to `collectRetainingPathForNotGCed`.
* Group global items related to leak tracking, in abstract class LeakTracking.
* Rename `gcCountBuffer` to `numberOfGcCycles` and `disposalTimeBuffer` to `disposalTime`.

## 8.0.3

* Fix an issue with custom gcCountBuffer values.

## 8.0.2

* Improve performance.
* Make gcCountBuffer customizable with default value 3.

## 8.0.1

* Handle SentinelException for retaining path.
* Limit number of requests for retaining path.

## 8.0.0

* Enable turn on/off tracking for leak types.
* Put all global flags into one class.

## 7.0.8

* Disconnect from service after obtaining retaining paths.
* Protect from identityHashCode equal to 0.

## 7.0.6

* Add helpers for troubleshooting.
* Handle generic arguments for retaining path detection.
* Convert to multi-package.

## 7.0.4

* Fix path collection.
* Create constructor to collect path.
* Fix connection issue.
* Improve retaining path formatting.
* Format retaining path nicely.
* Enable collection of retaining path.
* Separate testing.
* Fixes to support g3.
* Fix for MemoryUsageEvent constructor.

## 6.0.0

* Fix typo in public API.
* Add assertion for negative delay between snapshots.

## 5.0.0

* Migrate from auto-snapshotting to usage-tracking.
* Improve leak debugging UX.
* Fix failures in case of duplicates.

## 4.0.3

* Fix broken documentation link.

## 4.0.2

* Improve documentation.

## 4.0.1

* Autosnapshotting.

## 4.0.0

* Improve documentation and naming.

## 3.0.2

* Add members to `LeakTrackingTestConfig`.

## 3.0.1

* Increase sdk version
* Remove obsolete lint

## 3.0.0

* Breaking changes: update names of types to be align with Flutter naming convention.
* Add model for Flutter unit testing configuration.
* Adopt Flutter standard lints.
* Improve documentation.

## 2.0.1

* Minor changes.
* Updated `vm_service` version to >=9.0.0 <12.0.0.

## 2.0.0

* Breaking changes in `withLeakTracking`.
* Refactor test_infra libraries.
* Documentation updates.

## 1.0.0

* First release.
