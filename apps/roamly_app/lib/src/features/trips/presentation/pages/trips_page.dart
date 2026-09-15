import 'package:flutter/material.dart';

final class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Center(key: ValueKey<String>('trips-page'), child: Text('Trips')),
    );
  }
}
