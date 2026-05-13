import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/floating_glass_nav_bar.dart';
import '../../core/widgets/gradient_app_background.dart';

class PatientShell extends StatelessWidget {
  final Widget child;
  const PatientShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.patientDashboard,
    AppRoutes.appointments,
    AppRoutes.reports,
    AppRoutes.incidents,
    AppRoutes.chat,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  bool _showHeader(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return location == AppRoutes.patientDashboard;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final showHeader = _showHeader(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: GradientAppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (showHeader) const AppHeader(role: 'patient'),
              Expanded(
                child: GradientAppBackground(
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FloatingGlassNavBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          if (i != idx) context.go(_tabs[i]);
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
    );
  }
}
