import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/floating_glass_nav_bar.dart';
import '../../core/widgets/gradient_app_background.dart';

class DoctorShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DoctorShell({super.key, required this.navigationShell});

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: 'Schedule',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_alt_outlined),
      selectedIcon: Icon(Icons.people_alt_rounded),
      label: 'Patients',
    ),
    NavigationDestination(
      icon: Icon(Icons.fact_check_outlined),
      selectedIcon: Icon(Icons.fact_check_rounded),
      label: 'Review',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;
    final location = GoRouterState.of(context).uri.toString();
    final showHeader = location == AppRoutes.doctorDashboard;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GradientAppBackground(
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              if (showHeader) const AppHeader(role: 'doctor'),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FloatingGlassNavBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          if (i != idx) navigationShell.goBranch(i);
        },
        destinations: _destinations,
      ),
    );
  }
}
