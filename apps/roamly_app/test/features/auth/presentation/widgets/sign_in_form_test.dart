import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/auth/presentation/widgets/sign_in_form.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('SignInForm', () {
    testWidgets('renders the required sign-in controls at full width', (
      tester,
    ) async {
      await _pumpForm(tester);

      expect(find.byKey(const ValueKey('sign-in-form')), findsOneWidget);
      expect(find.byKey(const ValueKey('sign-in-email-field')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sign-in-password-field')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.signIn), findsOneWidget);
      expect(find.text(AppStrings.createAccount), findsOneWidget);

      final emailWidth = tester
          .getSize(_textFieldWithin('sign-in-email-field'))
          .width;
      final passwordWidth = tester
          .getSize(_textFieldWithin('sign-in-password-field'))
          .width;
      expect(emailWidth, 320);
      expect(passwordWidth, 320);
    });

    testWidgets('rejects empty credentials without submitting', (tester) async {
      var submitCalls = 0;
      await _pumpForm(tester, onSubmit: (_, _) async => submitCalls++);

      await tester.tap(find.text(AppStrings.signIn));
      await tester.pump();

      expect(find.text(AppStrings.emailRequired), findsOneWidget);
      expect(find.text(AppStrings.passwordRequired), findsOneWidget);
      expect(submitCalls, 0);
    });

    testWidgets('rejects an invalid email address', (tester) async {
      var submitCalls = 0;
      await _pumpForm(tester, onSubmit: (_, _) async => submitCalls++);
      await tester.enterText(
        _textFieldWithin('sign-in-email-field'),
        'not-an-email',
      );
      await tester.enterText(
        _textFieldWithin('sign-in-password-field'),
        'password',
      );

      await tester.tap(find.text(AppStrings.signIn));
      await tester.pump();

      expect(find.text(AppStrings.emailInvalid), findsOneWidget);
      expect(submitCalls, 0);
    });

    testWidgets('submits a trimmed email and unchanged password', (
      tester,
    ) async {
      String? submittedEmail;
      String? submittedPassword;
      await _pumpForm(
        tester,
        onSubmit: (email, password) async {
          submittedEmail = email;
          submittedPassword = password;
        },
      );
      await tester.enterText(
        _textFieldWithin('sign-in-email-field'),
        ' traveler@example.com ',
      );
      await tester.enterText(
        _textFieldWithin('sign-in-password-field'),
        ' password with spaces ',
      );

      await tester.tap(find.text(AppStrings.signIn));
      await tester.pump();

      expect(submittedEmail, 'traveler@example.com');
      expect(submittedPassword, ' password with spaces ');
    });

    testWidgets('submits from the password keyboard action', (tester) async {
      var submitCalls = 0;
      await _pumpForm(tester, onSubmit: (_, _) async => submitCalls++);
      await tester.enterText(
        _textFieldWithin('sign-in-email-field'),
        'traveler@example.com',
      );
      await tester.enterText(
        _textFieldWithin('sign-in-password-field'),
        'password',
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitCalls, 1);
    });

    testWidgets('disables inputs and actions while loading', (tester) async {
      var submitCalls = 0;
      var createAccountCalls = 0;
      await _pumpForm(
        tester,
        isLoading: true,
        onSubmit: (_, _) async => submitCalls++,
        onCreateAccount: () => createAccountCalls++,
      );

      final emailField = tester.widget<TextFormField>(
        _textFieldWithin('sign-in-email-field'),
      );
      final passwordField = tester.widget<TextFormField>(
        _textFieldWithin('sign-in-password-field'),
      );
      expect(emailField.enabled, isFalse);
      expect(passwordField.enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.tap(find.byType(TextButton));

      expect(submitCalls, 0);
      expect(createAccountCalls, 0);
    });

    testWidgets('invokes the create-account action', (tester) async {
      var createAccountCalls = 0;
      await _pumpForm(tester, onCreateAccount: () => createAccountCalls++);

      await tester.tap(find.text(AppStrings.createAccount));

      expect(createAccountCalls, 1);
    });

    testWidgets('announces a server error as a live region', (tester) async {
      await _pumpForm(tester, errorMessage: AppStrings.signInFailed);

      expect(find.text(AppStrings.signInFailed), findsOneWidget);
      final liveRegions = tester.widgetList<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(liveRegions, isNotEmpty);
    });
  });
}

Finder _textFieldWithin(String key) {
  return find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextFormField),
  );
}

Future<void> _pumpForm(
  WidgetTester tester, {
  SignInSubmitCallback? onSubmit,
  VoidCallback? onCreateAccount,
  bool isLoading = false,
  String? errorMessage,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RoamlyTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: SignInForm(
                onSubmit: onSubmit ?? (_, _) async {},
                onCreateAccount: onCreateAccount ?? () {},
                isLoading: isLoading,
                errorMessage: errorMessage,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
