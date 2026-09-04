import 'package:flutter/material.dart';

final class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('trips-page'),
      child: Text('Trips'),
    );
  }
}
