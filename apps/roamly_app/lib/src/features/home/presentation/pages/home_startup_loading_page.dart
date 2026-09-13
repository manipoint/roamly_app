import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/home_loading_view.dart';
import 'package:roamly_app/src/navigation/app_navigation_items.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class HomeStartupLoadingPage extends StatelessWidget {
  const HomeStartupLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoamlyScaffold(
      bodyPadding: EdgeInsets.zero,
      body: const HomeLoadingView(),
      bottomNavigationBar: ExcludeSemantics(
        child: IgnorePointer(
          child: RoamlyBottomNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: _ignoreDestinationSelection,
            items: appNavigationItems,
          ),
        ),
      ),
    );
  }

  static void _ignoreDestinationSelection(int _) {}
}
