import 'package:roamly_core/roamly_core.dart';

enum HomeDiscoveryFailureKind { invalidLimit, invalidResponse }

/// Safe failures owned by the Home discovery feature.
final class HomeDiscoveryFailure extends AppFailure {
  const HomeDiscoveryFailure.invalidLimit()
    : kind = HomeDiscoveryFailureKind.invalidLimit,
      super(code: 'home_discovery_invalid_limit', isRetryable: false);

  const HomeDiscoveryFailure.invalidResponse()
    : kind = HomeDiscoveryFailureKind.invalidResponse,
      super(code: 'home_discovery_invalid_response', isRetryable: false);

  final HomeDiscoveryFailureKind kind;
}
