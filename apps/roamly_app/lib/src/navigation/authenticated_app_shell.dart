import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_ui/roamly_ui.dart';

import 'app_navigation_items.dart';

final class AuthenticatedAppShell extends StatelessWidget {
  const AuthenticatedAppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoamlyScaffold(
      bodyPadding: EdgeInsets.zero,
      body: navigationShell,
      bottomNavigationBar: RoamlyBottomNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _selectDestination,
        items: appNavigationItems,
      ),
    );
  }
}
