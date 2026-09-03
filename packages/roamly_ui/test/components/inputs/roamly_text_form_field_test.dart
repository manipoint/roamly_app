import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('RoamlyTextFormField', () {
    testWidgets('forwards text input configuration', (tester) async {
      const autofillHints = <String>[AutofillHints.email];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await _pumpField(
        tester,
        RoamlyTextFormField(
          controller: controller,
          label: 'Email',
          hint: 'name@example.com',
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: autofillHints,
          prefixIcon: const Icon(Icons.email_outlined),
          suffixIcon: const Icon(Icons.clear),
          autocorrect: false,
          enableSuggestions: false,
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.controller, same(controller));
      expect(textField.focusNode, same(focusNode));
      expect(textField.keyboardType, TextInputType.emailAddress);
      expect(textField.textInputAction, TextInputAction.next);
      expect(textField.autofillHints, autofillHints);
      expect(textField.autocorrect, isFalse);
      expect(textField.enableSuggestions, isFalse);
      expect(textField.decoration?.labelText, 'Email');
      expect(textField.decoration?.hintText, 'name@example.com');
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('reports changes and submitted values', (tester) async {
      String? changedValue;
      String? submittedValue;

      await _pumpField(
        tester,
        RoamlyTextFormField(
          controller: controller,
          textInputAction: TextInputAction.done,
          onChanged: (value) => changedValue = value,
          onFieldSubmitted: (value) => submittedValue = value,
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'London');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(changedValue, 'London');
      expect(submittedValue, 'London');
    });

    testWidgets('displays synchronous validation errors', (tester) async {
      final formKey = GlobalKey<FormState>();

      await _pumpField(
        tester,
        RoamlyTextFormField(
          controller: controller,
          validator: (value) =>
              value == null || value.isEmpty ? 'Email is required' : null,
        ),
        formKey: formKey,
      );

      expect(formKey.currentState?.validate(), isFalse);
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('displays an asynchronous error supplied by the caller', (
      tester,
    ) async {
      await _pumpField(
        tester,
        RoamlyTextFormField(
          controller: controller,
          errorText: 'Account not found',
        ),
      );

      expect(find.text('Account not found'), findsOneWidget);
    });

    testWidgets('forwards obscured, disabled, and read-only states', (
      tester,
    ) async {
      await _pumpField(
        tester,
        RoamlyTextFormField(
          controller: controller,
          obscureText: true,
          enabled: false,
          readOnly: true,
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
      expect(textField.enabled, isFalse);
      expect(textField.readOnly, isTrue);
    });

    testWidgets('inherits the Roamly input theme', (tester) async {
      await _pumpField(tester, RoamlyTextFormField(controller: controller));

      final context = tester.element(find.byType(TextFormField));
      final inputTheme = Theme.of(context).inputDecorationTheme;

      expect(inputTheme.filled, isTrue);
      expect(
        inputTheme.focusedBorder,
        RoamlyTheme.light.inputDecorationTheme.focusedBorder,
      );
    });
  });
}

Future<void> _pumpField(
  WidgetTester tester,
  RoamlyTextFormField field, {
  GlobalKey<FormState>? formKey,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RoamlyTheme.light,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(RoamlySpacing.space16),
            child: field,
          ),
        ),
      ),
    ),
  );
}
