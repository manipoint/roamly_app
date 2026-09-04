/// User-facing English copy used by the Roamly application.
///
/// This provides a single source during Phase 1. It can later be replaced by
/// Flutter's generated localization system without changing domain packages.
abstract final class AppStrings {
  static const String appName = 'Roamly AI';
  static const String appNamePrefix = 'Roamly ';
  static const String appNameEmphasis = 'AI';
  static const String brandTagline = 'YOUR JOURNEY, PERFECTED.';

  static const String skip = 'Skip';
  static const String getStarted = 'Get Started';
  static const String welcomeHeadlineFirstLine = 'AI-Powered Trips.';
  static const String welcomeHeadlineSecondLine = 'Unforgettable';
  static const String welcomeHeadlineEmphasis = 'Journeys.';
  static const String welcomeDescription =
      'From hidden gems to iconic landmarks, Roamly AI creates '
      'personalized travel experiences just for you.';

  static const String welcomeBack = 'Welcome back';
  static const String signInSubtitle = 'Sign in to continue your journey';
  static const String createYourAccount = 'Create your account';
  static const String registerSubtitle =
      'Start your personalized travel experience';

  static const String emailLabel = 'Email';
  static const String emailHint = 'Enter your email';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String createPasswordHint = 'Create a password';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String confirmPasswordHint = 'Confirm your password';

  static const String signIn = 'Sign In';
  static const String forgotPassword = 'Forgot password?';
  static const String createAccount = 'Create account';
  static const String noAccount = "Don't have an account?";
  static const String haveAccount = 'Already have an account?';

  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';

  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String confirmPasswordRequired =
      'Password confirmation is required';
  static const String passwordTooShort =
      'Password must be at least 12 characters';
  static const String passwordTooLong =
      'Password must not exceed 128 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';

  static const String signInFailed =
      'Unable to sign in. Check your details and try again.';
  static const String registrationFailed =
      'Unable to create your account. Please try again.';
  static const String sessionRestoreFailed =
      'Unable to restore your session. Please sign in again.';
  static const String homeTab = 'Home';
  static const String tripsTab = 'Trips';
  static const String assistantTab = 'AI Assistant';
  static const String savedTab = 'Saved';
  static const String profileTab = 'Profile';
  static const String profile = 'Profile';
  static const String signedInAs = 'Signed in as';
  static const String account = 'Account';
  static const String signOut = 'Sign out';
  static const String signOutTitle = 'Sign out of Roamly?';
  static const String signOutConfirmation =
      'You will need to sign in again on this device.';
  static const String cancel = 'Cancel';
}
