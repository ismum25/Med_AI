import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  final String role;
  const ProfilePage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Profile',
                style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface)),
            const SizedBox(height: 8),
            Text('Coming soon',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
