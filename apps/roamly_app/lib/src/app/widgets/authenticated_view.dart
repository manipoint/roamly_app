import 'package:flutter/material.dart';

final class AuthenticatedView extends StatelessWidget {
  const AuthenticatedView({super.key,required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(email, key: const ValueKey('authenticated-view')),
      ),
    );
  }
}
