import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/floating_glass_nav_bar.dart';
import '../../core/widgets/gradient_app_background.dart';

class PatientShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PatientShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;
    final location = GoRouterState.of(context).uri.toString();
    final showHeader = location == AppRoutes.patientDashboard;
    return Scaffold(
      extendBody: false,
      backgroundColor: AppColors.surface,
      body: GradientAppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (showHeader) const AppHeader(role: 'patient'),
              Expanded(
                child: GradientAppBackground(
                  child: navigationShell,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GradientAppBackground(
        child: FloatingGlassNavBar(
          selectedIndex: idx,
          onDestinationSelected: (i) {
            if (i != idx) navigationShell.goBranch(i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Appointments',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.healing_outlined),
              selectedIcon: Icon(Icons.healing_rounded),
              label: 'Incidents',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}
