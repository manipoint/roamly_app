import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController(text: 'Secret123!');
  });

  tearDown(() {
    controller.dispose();
  });

  group('RoamlyPasswordFormField', () {
    testWidgets('composes RoamlyTextFormField with secure defaults', (
      tester,
    ) async {
      await _pumpPasswordField(tester, controller: controller);

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(find.byType(RoamlyTextFormField), findsOneWidget);
      expect(textField.obscureText, isTrue);
      expect(textField.keyboardType, TextInputType.visiblePassword);
      expect(textField.autocorrect, isFalse);
      expect(textField.enableSuggestions, isFalse);
      expect(textField.autofillHints, const [AutofillHints.password]);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byTooltip('Show password'), findsOneWidget);
    });

    testWidgets('toggles password visibility and accessible tooltip', (
      tester,
    ) async {
      await _pumpPasswordField(tester, controller: controller);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byTooltip('Hide password'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
      expect(find.byTooltip('Show password'), findsOneWidget);
    });

    testWidgets('disables the visibility action when the field is disabled', (
      tester,
    ) async {
      await _pumpPasswordField(tester, controller: controller, enabled: false);

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(iconButton.onPressed, isNull);
      expect(textField.enabled, isFalse);
      expect(textField.obscureText, isTrue);
    });

    testWidgets('forwards field configuration and new-password autofill', (
      tester,
    ) async {
      const autofillHints = <String>[AutofillHints.newPassword];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await _pumpPasswordField(
        tester,
        controller: controller,
        focusNode: focusNode,
        autofillHints: autofillHints,
        errorText: 'Password is too weak',
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.controller, same(controller));
      expect(textField.focusNode, same(focusNode));
      expect(textField.autofillHints, autofillHints);
      expect(find.text('Password is too weak'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('forwards validation, change, and submit callbacks', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      String? changedValue;
      String? submittedValue;

      await _pumpPasswordField(
        tester,
        controller: controller,
        formKey: formKey,
        validator: (value) => value == null || value.length < 8
            ? 'Use at least 8 characters'
            : null,
        onChanged: (value) => changedValue = value,
        onFieldSubmitted: (value) => submittedValue = value,
      );

      await tester.enterText(find.byType(TextFormField), 'short');
      expect(formKey.currentState?.validate(), isFalse);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(changedValue, 'short');
      expect(submittedValue, 'short');
      expect(find.text('Use at least 8 characters'), findsOneWidget);
    });
  });
}

Future<void> _pumpPasswordField(
  WidgetTester tester, {
  required TextEditingController controller,
  GlobalKey<FormState>? formKey,
  FocusNode? focusNode,
  Iterable<String>? autofillHints = const [AutofillHints.password],
  String? errorText,
  bool enabled = true,
  FormFieldValidator<String>? validator,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onFieldSubmitted,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RoamlyTheme.light,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: RoamlyPasswordFormField(
            controller: controller,
            showPasswordTooltip: 'Show password',
            hidePasswordTooltip: 'Hide password',
            label: 'Password',
            hint: 'Enter your password',
            errorText: errorText,
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            autofillHints: autofillHints,
            prefixIcon: const Icon(Icons.lock_outline),
            enabled: enabled,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
          ),
        ),
      ),
    ),
  );
}
