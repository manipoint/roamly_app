import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/auth/presentation/widgets/register_form.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RegisterForm', () {
    testWidgets('renders distinct registration fields at full width', (
      tester,
    ) async {
      await _pumpForm(tester);

      expect(find.byKey(const ValueKey('register-form')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('register-email-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('register-password-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('register-confirm-password-field')),
        findsOneWidget,
      );

      for (final key in <String>[
        'register-email-field',
        'register-password-field',
        'register-confirm-password-field',
      ]) {
        expect(tester.getSize(_textFieldWithin(key)).width, 320);
      }
    });

    testWidgets('rejects empty registration fields', (tester) async {
      var submitCalls = 0;
      await _pumpForm(tester, onSubmit: (_, _) async => submitCalls++);

      await tester.tap(find.text(AppStrings.createAccount));
      await tester.pump();

      expect(find.text(AppStrings.emailRequired), findsOneWidget);
      expect(find.text(AppStrings.passwordRequired), findsOneWidget);
      expect(find.text(AppStrings.confirmPasswordRequired), findsOneWidget);
      expect(submitCalls, 0);
    });

    testWidgets('enforces the backend registration password minimum', (
      tester,
    ) async {
      var submitCalls = 0;
      await _pumpForm(tester, onSubmit: (_, _) async => submitCalls++);
      await _enterRegistration(
        tester,
        email: 'traveler@example.com',
        password: 'short',
        confirmation: 'short',
      );

      await tester.tap(find.text(AppStrings.createAccount));
      await tester.pump();

      expect(find.text(AppStrings.passwordTooShort), findsOneWidget);
      expect(submitCalls, 0);
    });

    testWidgets('rejects a confirmation that does not match', (tester) async {
      var submitCalls = 0;
      await _pumpForm(tester, onSubmit: (_, _) async => submitCalls++);
      await _enterRegistration(
        tester,
        email: 'traveler@example.com',
        password: 'valid-password',
        confirmation: 'other-password',
      );

      await tester.tap(find.text(AppStrings.createAccount));
      await tester.pump();

      expect(find.text(AppStrings.passwordsDoNotMatch), findsOneWidget);
      expect(submitCalls, 0);
    });

    testWidgets('submits trimmed email and unchanged matching password', (
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
      const password = ' valid password ';
      await _enterRegistration(
        tester,
        email: ' traveler@example.com ',
        password: password,
        confirmation: password,
      );

      await tester.tap(find.text(AppStrings.createAccount));
      await tester.pump();

      expect(submittedEmail, 'traveler@example.com');
      expect(submittedPassword, password);
    });

    testWidgets('submits from confirmation keyboard action', (tester) async {
      var submitCalls = 0;
      await _pumpForm(tester, onSubmit: (_, _) async => submitCalls++);
      await _enterRegistration(
        tester,
        email: 'traveler@example.com',
        password: 'valid-password',
        confirmation: 'valid-password',
      );

      await tester.showKeyboard(
        _textFieldWithin('register-confirm-password-field'),
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitCalls, 1);
    });

    testWidgets('disables fields and actions while loading', (tester) async {
      var submitCalls = 0;
      var signInCalls = 0;
      await _pumpForm(
        tester,
        isLoading: true,
        onSubmit: (_, _) async => submitCalls++,
        onSignIn: () => signInCalls++,
      );

      for (final key in <String>[
        'register-email-field',
        'register-password-field',
        'register-confirm-password-field',
      ]) {
        expect(
          tester.widget<TextFormField>(_textFieldWithin(key)).enabled,
          false,
        );
      }
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.tap(find.byType(TextButton));

      expect(submitCalls, 0);
      expect(signInCalls, 0);
    });

    testWidgets('invokes sign-in action and announces server errors', (
      tester,
    ) async {
      var signInCalls = 0;
      await _pumpForm(
        tester,
        errorMessage: 'Registration failed',
        onSignIn: () => signInCalls++,
      );

      await tester.tap(find.text(AppStrings.signIn));

      expect(signInCalls, 1);
      expect(find.text('Registration failed'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
        findsWidgets,
      );
    });
  });
}

Finder _textFieldWithin(String key) {
  return find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextFormField),
  );
}

Future<void> _enterRegistration(
  WidgetTester tester, {
  required String email,
  required String password,
  required String confirmation,
}) async {
  await tester.enterText(_textFieldWithin('register-email-field'), email);
  await tester.enterText(_textFieldWithin('register-password-field'), password);
  await tester.enterText(
    _textFieldWithin('register-confirm-password-field'),
    confirmation,
  );
}

Future<void> _pumpForm(
  WidgetTester tester, {
  RegisterSubmitCallback? onSubmit,
  VoidCallback? onSignIn,
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
              child: RegisterForm(
                onSubmit: onSubmit ?? (_, _) async {},
                onSignIn: onSignIn ?? () {},
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
