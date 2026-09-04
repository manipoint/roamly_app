import 'package:flutter/material.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
     return const Center(
      key: ValueKey<String>('saved-page'),
      child: Text('Saved'),
    );
  }
}
