import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.go(AppRoutes.login)),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _DashboardCard(
            icon: Icons.calendar_today,
            title: 'Appointments',
            color: Colors.blue,
            onTap: () => context.push(AppRoutes.appointments),
          ),
          _DashboardCard(
            icon: Icons.upload_file,
            title: 'Upload Report',
            color: Colors.green,
            onTap: () => context.push(AppRoutes.uploadReport),
          ),
          _DashboardCard(
            icon: Icons.folder_shared,
            title: 'My Reports',
            color: Colors.orange,
            onTap: () => context.push(AppRoutes.reports),
          ),
          _DashboardCard(
            icon: Icons.chat,
            title: 'AI Assistant',
            color: Colors.purple,
            onTap: () => context.push(AppRoutes.chat),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 30,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
