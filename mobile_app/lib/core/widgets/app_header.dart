import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/api_endpoints.dart';
import '../network/dio_client.dart';
import '../theme/app_theme.dart';
import '../../injection_container.dart';

class AppHeader extends StatefulWidget {
  final String role;
  const AppHeader({super.key, required this.role});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String _name = '';
  String _roleLabel = '';
  final bool _hasNotification = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = sl<DioClient>();
      final response = await client.dio.get(ApiEndpoints.myProfile);
      final data = response.data as Map<String, dynamic>;
      final fullName = (data['full_name'] as String?) ?? '';
      final specialization = data['specialization'] as String?;
      if (mounted) {
        setState(() {
          _name = fullName;
          _roleLabel = widget.role == 'doctor'
              ? (specialization != null && specialization.isNotEmpty
                  ? specialization
                  : 'Doctor')
              : 'Patient';
        });
      }
    } catch (_) {
      // Non-critical — header shows placeholder if profile fetch fails
    }
  }

  String get _initials {
    if (_name.isEmpty) return widget.role == 'doctor' ? 'Dr' : 'P';
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String get _displayName {
    if (_name.isEmpty) return widget.role == 'doctor' ? 'Doctor' : 'User';
    return widget.role == 'doctor' ? 'Dr. ${_name.split(' ').first}' : _name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _roleLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 22,
                ),
              ),
              if (_hasNotification)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
