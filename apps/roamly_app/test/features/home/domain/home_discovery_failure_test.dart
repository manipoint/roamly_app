import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/failures/home_discovery_failure.dart';

void main() {
  test('failure factories expose stable and unique non-retryable codes', () {
    const cases = <(HomeDiscoveryFailure, HomeDiscoveryFailureKind)>[
      (
        HomeDiscoveryFailure.invalidLimit(),
        HomeDiscoveryFailureKind.invalidLimit,
      ),
      (
        HomeDiscoveryFailure.invalidResponse(),
        HomeDiscoveryFailureKind.invalidResponse,
      ),
    ];

    expect(
      cases.map((entry) => entry.$1.code).toSet(),
      hasLength(cases.length),
    );
    for (final (failure, kind) in cases) {
      expect(failure.kind, kind);
      expect(failure.code, startsWith('home_discovery_'));
      expect(failure.isRetryable, isFalse);
    }
  });
}
