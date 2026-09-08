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
  static const String loadingPreferences = 'Loading your travel preferences';

  static const String preferencesLoadFailed =
      'We could not load your travel preferences. Please try again.';

  static const String tryAgain = 'Try again';
  static const String continueLabel = 'Continue';
  static const String travelStyleTitlePrefix = "What's your ";
  static const String travelStyleTitleEmphasis = 'travel style?';

  static const String travelStyleDescription =
      "Pick what inspires you — we'll tailor every journey to you.";

  static const String travelStyleBeaches = 'Beaches';
  static const String travelStyleAdventure = 'Adventure';
  static const String travelStyleFood = 'Food';
  static const String travelStyleLuxury = 'Luxury';
  static const String travelStyleNature = 'Nature';
  static const String travelStyleCulture = 'Culture';
  static const String interestsBudgetTitlePrefix = 'Tell us your\n';
  static const String interestsBudgetTitleEmphasis = 'interests & budget';
  static const String interestsBudgetDescription =
      'The more you share, the better we plan your perfect trip.';
  static const String interestsQuestion = 'What interests you?';
  static const String interestLimitMessage =
      'You can select up to 5 interests.';
  static const String budgetPerPerson = 'Budget per person';
  static const String budgetInformation =
      'Choose your usual spending preference per person.';
  static const String tripPreference = 'Trip preference';
  static const String tripPreferenceInformation =
      'Choose how full you want each day of your trip to be.';
  static const String interestHiking = 'Hiking';
  static const String interestPhotography = 'Photography';
  static const String interestNightlife = 'Nightlife';
  static const String interestWellness = 'Wellness';
  static const String interestHistory = 'History';
  static const String interestWildlife = 'Wildlife';
  static const String interestShopping = 'Shopping';
  static const String interestLocalCulture = 'Local Culture';
  static const String interestEvents = 'Events';
  static const String budget = 'Budget';
  static const String midRange = 'Mid-range';
  static const String premium = 'Premium';
  static const String luxury = 'Luxury';
  static const String paceRelaxed = 'Relaxed';
  static const String paceRelaxedDescription = 'Slow & easy';
  static const String paceBalanced = 'Balanced';
  static const String paceBalancedDescription = 'Mix of both';
  static const String pacePacked = 'Packed';
  static const String pacePackedDescription = 'See it all';

  static String preferenceProgress(int currentStep, int stepCount) {
    return 'Step $currentStep of $stepCount';
  }
}
