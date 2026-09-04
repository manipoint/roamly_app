import 'package:roamly_app/src/localization/app_strings.dart';

abstract final class RoamlyValidators {
  static const int minimumRegistrationPasswordLength = 12;
  static const int maximumPasswordLength = 128;

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return AppStrings.emailRequired;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return AppStrings.emailInvalid;
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }

    if (value.length > maximumPasswordLength) {
      return AppStrings.passwordTooLong;
    }

    return null;
  }

  static String? validateRegistrationPassword(String? value) {
    final requiredError = validatePassword(value);
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.length < minimumRegistrationPasswordLength) {
      return AppStrings.passwordTooShort;
    }

    return null;
  }

  static String? validatePasswordConfirmation(
    String? value, {
    required String password,
  }) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }

    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }

    return null;
  }
}
