import 'package:flutter/material.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Center(
        key: ValueKey<String>('assistant-page'),
        child: Text('Assistant'),
      ),
    );
  }
}
