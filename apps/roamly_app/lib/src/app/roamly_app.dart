import 'package:flutter/material.dart';
import 'package:roamly_app/src/app/auth_gate.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class RoamlyApp extends StatelessWidget {
  const RoamlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roamly AI',
      theme: RoamlyTheme.light,
      darkTheme: RoamlyTheme.dark,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
