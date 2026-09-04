import 'package:flutter/material.dart';
import 'package:roamly_app/src/app/validator/roamly_validators.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

typedef RegisterSubmitCallback =
    Future<void> Function(String email, String password);

final class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    required this.onSubmit,
    required this.onSignIn,
    this.isLoading = false,
    this.errorMessage,
  });
  final RegisterSubmitCallback onSubmit;
  final VoidCallback onSignIn;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

final class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.isLoading) {
      return;
    }
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    await widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('register-form'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoamlyTextFormField(
              key: const ValueKey('register-email-field'),
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: AppStrings.emailLabel,
              hint: AppStrings.emailHint,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              prefixIcon: const Icon(Icons.email_outlined),
              enabled: !widget.isLoading,
              validator: RoamlyValidators.validateEmail,
              onFieldSubmitted: (_) {
                _passwordFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: RoamlySpacing.space20),
            RoamlyPasswordFormField(
              key: const ValueKey('register-password-field'),
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: AppStrings.passwordLabel,
              hint: AppStrings.createPasswordHint,
              showPasswordTooltip: AppStrings.showPassword,
              hidePasswordTooltip: AppStrings.hidePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: const Icon(Icons.lock_outline),
              enabled: !widget.isLoading,
              validator: RoamlyValidators.validateRegistrationPassword,
              onFieldSubmitted: (_) {
                _confirmPasswordFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: RoamlySpacing.space20),
            RoamlyPasswordFormField(
              key: const ValueKey('register-confirm-password-field'),
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: AppStrings.confirmPasswordLabel,
              hint: AppStrings.confirmPasswordHint,
              showPasswordTooltip: AppStrings.showPassword,
              hidePasswordTooltip: AppStrings.hidePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: const Icon(Icons.lock_outline),
              enabled: !widget.isLoading,
              validator: (value) {
                return RoamlyValidators.validatePasswordConfirmation(
                  value,
                  password: _passwordController.text,
                );
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.errorMessage == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('register-error'),
                      padding: const EdgeInsets.only(
                        top: RoamlySpacing.space16,
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          widget.errorMessage!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: colors.error),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: RoamlySpacing.space24),
            RoamlyButton.primary(
              label: AppStrings.createAccount,
              onPressed: _submit,
              isLoading: widget.isLoading,
              expand: true,
            ),
            const SizedBox(height: RoamlySpacing.space16),
            RoamlyInlineAction(
              prompt: AppStrings.haveAccount,
              actionLabel: AppStrings.signIn,
              onPressed: widget.isLoading ? null : widget.onSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
