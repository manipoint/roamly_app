import 'package:flutter/material.dart';

final class UnauthenticatedView extends StatelessWidget {
  const UnauthenticatedView({super.key, required this.hasFailure});
  final bool hasFailure;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          hasFailure
              ? 'Unable to restore your session.'
              : 'Sign in to continue.',
          key: const ValueKey('unauthenticated-view'),
        ),
      ),
    );
  }
}
