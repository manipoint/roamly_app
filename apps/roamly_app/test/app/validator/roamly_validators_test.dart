import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/app/validator/roamly_validators.dart';
import 'package:roamly_app/src/localization/app_strings.dart';

void main() {
  group('validateEmail', () {
    test('requires a non-empty email', () {
      expect(RoamlyValidators.validateEmail(null), AppStrings.emailRequired);
      expect(RoamlyValidators.validateEmail('  '), AppStrings.emailRequired);
    });

    test('accepts a trimmed address and rejects malformed values', () {
      expect(RoamlyValidators.validateEmail(' user@example.com '), isNull);
      expect(
        RoamlyValidators.validateEmail('user@example'),
        AppStrings.emailInvalid,
      );
      expect(
        RoamlyValidators.validateEmail('user @example.com'),
        AppStrings.emailInvalid,
      );
    });
  });

  group('password validation', () {
    test('login password only enforces required and maximum length', () {
      expect(
        RoamlyValidators.validatePassword(null),
        AppStrings.passwordRequired,
      );
      expect(RoamlyValidators.validatePassword('short'), isNull);
      expect(
        RoamlyValidators.validatePassword(
          List<String>.filled(
            RoamlyValidators.maximumPasswordLength + 1,
            'x',
          ).join(),
        ),
        AppStrings.passwordTooLong,
      );
    });

    test('registration additionally enforces its minimum length', () {
      expect(
        RoamlyValidators.validateRegistrationPassword('short'),
        AppStrings.passwordTooShort,
      );
      expect(
        RoamlyValidators.validateRegistrationPassword(
          List<String>.filled(
            RoamlyValidators.minimumRegistrationPasswordLength,
            'x',
          ).join(),
        ),
        isNull,
      );
    });

    test('confirmation is required and must exactly match', () {
      expect(
        RoamlyValidators.validatePasswordConfirmation(null, password: 'secret'),
        AppStrings.confirmPasswordRequired,
      );
      expect(
        RoamlyValidators.validatePasswordConfirmation(
          'different',
          password: 'secret',
        ),
        AppStrings.passwordsDoNotMatch,
      );
      expect(
        RoamlyValidators.validatePasswordConfirmation(
          'secret',
          password: 'secret',
        ),
        isNull,
      );
    });
  });
}
