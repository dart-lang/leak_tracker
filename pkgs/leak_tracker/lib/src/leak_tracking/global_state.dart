// ignore: avoid_classes_with_only_static_members, as it is ok for enum-like classes.

import '_global_state.dart';

// ignore: avoid_classes_with_only_static_members, as it is ok for enum-like classes.
/// Global settings for leak tracker.
class LeakTrackerGlobalState {
  /// If true, a warning will be printed when leak tracking is
  /// requested for a non-supported platform.
  static bool warnForNonSupportedPlatforms = true;

  /// Limit for number of requests for retaining path per one round
  /// of validation for leaks.
  ///
  /// If the number is too big, the performance may be seriously impacted.
  /// If null, the path will be requested without limit.
  static int? maxRequestsForRetainingPath = 10;

  static bool get isTrackingInProcess =>
      InternalGlobalState.isTrackingInProcess;

  static bool get isTrackingPaused => throw UnimplementedError();

  static String get phase => throw UnimplementedError();
}
