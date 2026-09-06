import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/preference_failure.dart';
import 'package:roamly_core/roamly_core.dart';

void main() {
  final cases = [
    (
      PreferenceFailure.invalidInterestCount(),
      PreferenceFailureKind.invalidInterestCount,
      'preference_invalid_interest_count',
    ),
    (
      PreferenceFailure.homeLocationRequired(),
      PreferenceFailureKind.homeLocationRequired,
      'preference_home_location_required',
    ),
    (
      PreferenceFailure.invalidHomeLocation(),
      PreferenceFailureKind.invalidHomeLocation,
      'preference_invalid_home_location',
    ),
    (
      PreferenceFailure.invalidResponse(),
      PreferenceFailureKind.invalidResponse,
      'preference_invalid_response',
    ),
  ];

  for (final (failure, kind, code) in cases) {
    test('$code exposes the correct safe, non-retryable failure', () {
      expect(failure, isA<AppFailure>());
      expect(failure.kind, kind);
      expect(failure.code, code);
      expect(failure.isRetryable, isFalse);
    });
  }

  test('all failure kinds have distinct codes', () {
    expect(
      cases.map((entry) => entry.$1.kind).toSet(),
      PreferenceFailureKind.values.toSet(),
    );
    expect(cases.map((entry) => entry.$1.code).toSet().length, cases.length);
  });
}
