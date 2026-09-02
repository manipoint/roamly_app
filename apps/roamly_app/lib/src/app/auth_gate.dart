import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/app/widgets/authenticated_view.dart';
import 'package:roamly_app/src/app/widgets/session_loading_view.dart';
import 'package:roamly_app/src/app/widgets/unauthenticated_view.dart';
import 'package:roamly_auth/roamly_auth.dart';

final class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authControllerProvider);
    if (authSession.isLoading && !authSession.hasValue) {
      return const SessionLoadingView(valueKey: 'auth-session-loading',);
    }
    final user = authSession.value;
    if (user == null) {
      return UnauthenticatedView(hasFailure:authSession.hasError);
    }
    return  AuthenticatedView(email:user.email);
  }
}


