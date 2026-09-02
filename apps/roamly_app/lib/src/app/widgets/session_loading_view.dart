import 'package:flutter/material.dart';

final class SessionLoadingView extends StatelessWidget {
  const SessionLoadingView({super.key, required this.valueKey});
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator.adaptive(key: Key(valueKey)),
      ),
    );
  }
}
