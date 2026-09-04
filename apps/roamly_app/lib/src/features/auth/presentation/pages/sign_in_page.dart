import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:roamly_app/src/features/auth/presentation/widgets/sign_in_form.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_auth/roamly_auth.dart';

final class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

final class _SignInPageState extends ConsumerState<SignInPage> {
  bool _hasSubmitted = false;
  Future<void> _signIn(String email, String password) async {
    if (!_hasSubmitted) {
      setState(() {
        _hasSubmitted = true;
      });
    }
    await ref
        .read(authControllerProvider.notifier)
        .signIn(email: email, password: password);
    if (!mounted) {
      return;
    }
    final authState = ref.read(authControllerProvider);
    if (authState.hasValue && authState.value != null) {
      TextInput.finishAutofillContext();
    }
  }

  void _openRegistration() {
    context.goNamed(AppRouteNames.register);
  }

  String? _errorMessage(AsyncValue<AuthUser?> authState) {
    if (!authState.hasError) {
      return null;
    }
    return _hasSubmitted
        ? AppStrings.signInFailed
        : AppStrings.sessionRestoreFailed;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthPageLayout(
      title: AppStrings.welcomeBack,
      subtitle: AppStrings.signInSubtitle,
      child: SignInForm(
        onSubmit: _signIn,
        onCreateAccount: _openRegistration,
        isLoading: authState.isLoading,
        errorMessage: _errorMessage(authState),
      ),
    );
  }
}
