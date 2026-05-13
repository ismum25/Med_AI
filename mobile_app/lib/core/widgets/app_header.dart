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
  String _specialization = '';
  final bool _hasNotification = false;

  static final _nameStyle = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static final _chipLabelStyle = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

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
    return widget.role == 'doctor'
        ? 'Dr. ${_name.split(' ').first}'
        : _name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceContainerLowest.withValues(alpha: 0.96),
              AppColors.surfaceContainerLow.withValues(alpha: 0.88),
              AppColors.primaryContainer.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(
              color: AppColors.outline.withValues(alpha: 0.18),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => context.go(
                  widget.role == 'doctor'
                      ? AppRoutes.doctorProfile
                      : AppRoutes.patientProfile,
                ),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 13,
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
                              style: _nameStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _HeaderChip(
                                  label: widget.role == 'doctor'
                                      ? 'Doctor'
                                      : 'Patient',
                                  emphasized: true,
                                  labelStyle: _chipLabelStyle,
                                ),
                                if (widget.role == 'doctor' &&
                                    _specialization.isNotEmpty)
                                  _HeaderChip(
                                    label: _specialization,
                                    emphasized: false,
                                    labelStyle: _chipLabelStyle,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 19,
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
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final bool emphasized;
  final TextStyle labelStyle;

  const _HeaderChip({
    required this.label,
    required this.emphasized,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.surfaceContainerLowest.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(999),
        border: emphasized
            ? null
            : Border.all(
                color: AppColors.outline.withValues(alpha: 0.20),
              ),
      ),
      child: Text(
        label,
        style: labelStyle.copyWith(
          color: emphasized ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
