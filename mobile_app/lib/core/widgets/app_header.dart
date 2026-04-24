import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_routes.dart';
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
  /// Doctor profile only; empty for patients.
  String _specialization = '';
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
      final spec = (data['specialization'] as String?)?.trim() ?? '';
      if (mounted) {
        setState(() {
          _name = fullName;
          _specialization = widget.role == 'doctor' ? spec : '';
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
          // Avatar + name — tappable, navigates to profile
          Expanded(
            child: InkWell(
              onTap: () => context.go(
                widget.role == 'doctor'
                    ? AppRoutes.doctorProfile
                    : AppRoutes.patientProfile,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
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
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _HeaderChip(
                                label:
                                    widget.role == 'doctor' ? 'Doctor' : 'Patient',
                                emphasized: true,
                              ),
                              if (widget.role == 'doctor' &&
                                  _specialization.isNotEmpty)
                                _HeaderChip(
                                  label: _specialization,
                                  emphasized: false,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

class _HeaderChip extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _HeaderChip({required this.label, required this.emphasized});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: emphasized
            ? null
            : Border.all(
                color: AppColors.outline.withValues(alpha: 0.35),
              ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: emphasized ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
