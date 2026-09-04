import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:roamly_app/src/features/auth/presentation/widgets/register_form.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_auth/roamly_auth.dart';

final class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

final class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool _hasSubmitted = false;

  Future<void> _register(String email, String password) async {
    if (!_hasSubmitted) {
      setState(() {
        _hasSubmitted = true;
      });
    }

    await ref
        .read(authControllerProvider.notifier)
        .register(email: email, password: password);

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.hasValue && authState.value != null) {
      TextInput.finishAutofillContext();
    }
  }

  void _openSignIn() {
    context.goNamed(AppRouteNames.signIn);
  }

  String? _errorMessage(AsyncValue<AuthUser?> authState) {
    if (!authState.hasError) {
      return null;
    }

    return _hasSubmitted
        ? AppStrings.registrationFailed
        : AppStrings.sessionRestoreFailed;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthPageLayout(
      title: AppStrings.createYourAccount,
      subtitle: AppStrings.registerSubtitle,
      child: RegisterForm(
        onSubmit: _register,
        onSignIn: _openSignIn,
        isLoading: authState.isLoading,
        errorMessage: _errorMessage(authState),
      ),
    );
  }
}
