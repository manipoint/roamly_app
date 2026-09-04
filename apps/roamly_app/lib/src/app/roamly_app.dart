import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/navigation/app_router.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class RoamlyApp extends ConsumerWidget {
  const RoamlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Roamly AI',
      theme: RoamlyTheme.light,
      darkTheme: RoamlyTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
