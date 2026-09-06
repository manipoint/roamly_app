import 'package:roamly_core/roamly_core.dart';

/// Expected failures specific to preference operations.
enum PreferenceFailureKind {
  invalidInterestCount,
  homeLocationRequired,
  invalidHomeLocation,
  invalidResponse,
}

/// Safe preference failures without raw payloads or exception messages.
///
/// Localized messages belong in the presentation layer.
final class PreferenceFailure extends AppFailure {
  const PreferenceFailure.invalidInterestCount()
    : kind = PreferenceFailureKind.invalidInterestCount,
      super(code: 'preference_invalid_interest_count', isRetryable: false);

  const PreferenceFailure.homeLocationRequired()
    : kind = PreferenceFailureKind.homeLocationRequired,
      super(code: 'preference_home_location_required', isRetryable: false);

  const PreferenceFailure.invalidHomeLocation()
    : kind = PreferenceFailureKind.invalidHomeLocation,
      super(code: 'preference_invalid_home_location', isRetryable: false);
  const PreferenceFailure.invalidResponse()
    : kind = PreferenceFailureKind.invalidResponse,
      super(code: 'preference_invalid_response', isRetryable: false);
  final PreferenceFailureKind kind;
}
