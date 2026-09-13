import 'package:flutter/material.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

const appNavigationItems = <RoamlyNavigationItem>[
  RoamlyNavigationItem(
    label: AppStrings.homeTab,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  RoamlyNavigationItem(
    label: AppStrings.tripsTab,
    icon: Icons.luggage_outlined,
    selectedIcon: Icons.luggage,
  ),
  RoamlyNavigationItem(
    label: AppStrings.assistantTab,
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
  ),
  RoamlyNavigationItem(
    label: AppStrings.savedTab,
    icon: Icons.bookmark_outline,
    selectedIcon: Icons.bookmark,
  ),
  RoamlyNavigationItem(
    label: AppStrings.profileTab,
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];
