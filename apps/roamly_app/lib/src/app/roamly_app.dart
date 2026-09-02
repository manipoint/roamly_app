import 'package:flutter/material.dart';
import 'package:roamly_app/src/app/auth_gate.dart';

final class RoamlyApp extends StatelessWidget {
  const RoamlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roamly AI',
      home: AuthGate(),
    );
  }
}
