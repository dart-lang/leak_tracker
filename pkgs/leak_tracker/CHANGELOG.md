# 9.0.7

* Use ObjectRecord instead of hash code to identify objects.
* Remove collection of stack trace by class in LeakDiagnosticConfig.
* Bump version of SDK to 3.1.2.

# 9.0.6

* Improve error reporting for connection to vm service.
* Fix misspelling.
* Enable memory baselining.

# 9.0.5

* Fix issue of using wrong settings for a phase, so that the tracker uses settings
at time of object tracking start, instead of current configuration.

# 9.0.4

* Make it possible to disable tracking for a type of leak.

# 9.0.3

* Stop failing if an object is disposed twice.

# 9.0.2

* Make sure phase bondaries are handled correctly.

# 9.0.1

* Auto-start VM Service when needed.

# 9.0.0

* Refactor to improve performance of regression tests with leak tracking.
* Remove API that is not used in Flutter Framework.
* Rename `LeakTrackingConfiguration` to `LeakTrackingConfig`.
* Remove global flag [collectDebugInformationForLeaks].
* Rename `checkNonGCed` to `checkNotGCed` and `collectRetainingPathForNonGCed` to `collectRetainingPathForNotGCed`.
* Group global items related to leak tracking, in abstract class LeakTracking.
* Rename `gcCountBuffer` to `numberOfGcCycles` and `disposalTimeBuffer` to `disposalTime`.

# 8.0.3

* Fix an issue with custom gcCountBuffer values.

# 8.0.2

* Improve performance.
* Make gcCountBuffer customizable with default value 3.

# 8.0.1

* Handle SentinelException for retaining path.
* Limit number of requests for retaining path.

# 8.0.0

* Enable turn on/off tracking for leak types.
* Put all global flags into one class.

# 7.0.8

* Disconnect from service after obtaining retaining paths.
* Protect from identityHashCode equal to 0.

# 7.0.6

* Add helpers for troubleshooting.
* Handle generic arguments for retaining path detection.
* Convert to multi-package.

# 7.0.4

* Fix path collection.
* Create constructor to collect path.
* Fix connection issue.
* Improve retaining path formatting.
* Format retaining path nicely.
* Enable collection of retaining path.
* Separate testing.
* Fixes to support g3.
* Fix for MemoryUsageEvent constructor.

# 6.0.0

* Fix typo in public API.
* Add assersion for negative delay between snapshots.

# 5.0.0

* Migrate from auto-snapshotting to usage-tracking.
* Improve leak debugging UX.
* Fix failures in case of duplicates.

# 4.0.3

* Fix broken documentation link.

# 4.0.2

* Improve documentation.

# 4.0.1

* Autosnapshotting.

# 4.0.0

* Improve documentation and naming.
# 3.0.2

* Add members to `LeakTrackingTestConfig`.

# 3.0.1

* Increase sdk version
* Remove obsolet lint

# 3.0.0

* Breaking changes: update names of types to be align with Flutter naming convention.
* Add model for Flutter unit testing configuration.
* Adopt Flutter standard lints.
* Improve documentation.

# 2.0.1

* Minor changes.
* Updated `vm_service` version to >=9.0.0 <12.0.0.

# 2.0.0

* Breaking changes in `withLeakTracking`.
* Refactor test_infra libraries.
* Documentation updates.

# 1.0.0

* First release.
