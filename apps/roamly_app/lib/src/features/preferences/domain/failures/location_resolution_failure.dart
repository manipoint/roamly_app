import 'package:roamly_core/roamly_core.dart';

enum LocationResolutionFailureKind {
  invalidQuery,
  invalidLimit,
  invalidResponse,
}

/// Safe failures produced specifically by canonical location resolution.
final class LocationResolutionFailure extends AppFailure {
  const LocationResolutionFailure.invalidQuery()
    : kind = LocationResolutionFailureKind.invalidQuery,
      super(code: 'location_resolution_invalid_query', isRetryable: false);

  const LocationResolutionFailure.invalidLimit()
    : kind = LocationResolutionFailureKind.invalidLimit,
      super(code: 'location_resolution_invalid_limit', isRetryable: false);

  const LocationResolutionFailure.invalidResponse()
    : kind = LocationResolutionFailureKind.invalidResponse,
      super(code: 'location_resolution_invalid_response', isRetryable: false);

  final LocationResolutionFailureKind kind;
}
