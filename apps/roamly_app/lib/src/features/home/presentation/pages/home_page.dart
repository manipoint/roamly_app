import 'package:flutter/material.dart';

final class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('home-page'),
      child: Text('Home'),
    );
  }
}
