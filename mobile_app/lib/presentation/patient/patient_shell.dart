import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';

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

  bool _isMainTabPage(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    // Check if location is exactly a main tab (no sub-routes like /incidents/123 or /incidents/upload)
    for (final tab in _tabs) {
      if (location == tab) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final isMainPage = _isMainTabPage(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (isMainPage) const AppHeader(role: 'patient'),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(_tabs[i]),
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
      ),
    );
  }
}
