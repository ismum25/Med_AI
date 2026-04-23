import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final client = sl<DioClient>();
      final response = await client.dio.get(ApiEndpoints.myProfile);
      if (mounted) {
        setState(() {
          _profile = response.data as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load profile';
          _loading = false;
        });
      }
    }
  }

  String get _initials {
    final name = (_profile?['full_name'] as String?) ?? '';
    if (name.isEmpty) return widget.role == 'doctor' ? 'Dr' : 'P';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get _displayName {
    final name = (_profile?['full_name'] as String?) ?? '';
    if (name.isEmpty) return widget.role == 'doctor' ? 'Doctor' : 'User';
    return widget.role == 'doctor'
        ? 'Dr. ${name.split(' ').first}'
        : name;
  }

  String get _roleLabel {
    if (widget.role == 'doctor') {
      final spec = (_profile?['specialization'] as String?) ?? '';
      return spec.isNotEmpty ? spec : 'Doctor';
    }
    return 'Patient';
  }

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'remember_me');
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _fetchProfile();
                  },
                )
              : _ProfileBody(
                  profile: _profile!,
                  role: widget.role,
                  initials: _initials,
                  displayName: _displayName,
                  roleLabel: _roleLabel,
                  onLogout: () => _logout(context),
                  onRefresh: _fetchProfile,
                ),
    );
  }
}

// ─────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────
class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String role;
  final String initials;
  final String displayName;
  final String roleLabel;
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;

  const _ProfileBody({
    required this.profile,
    required this.role,
    required this.initials,
    required this.displayName,
    required this.roleLabel,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Hero banner
          _HeroBanner(
              initials: initials,
              displayName: displayName,
              roleLabel: roleLabel),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info section
                _SectionLabel('Personal Info'),
                const SizedBox(height: 10),
                _InfoCard(children: [
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: (profile['email'] as String?) ?? '—',
                  ),
                  if (role == 'patient') ...[
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Date of Birth',
                      value: _fmt(profile['date_of_birth']),
                    ),
                    _InfoRow(
                      icon: Icons.bloodtype_outlined,
                      label: 'Blood Type',
                      value: _fmt(profile['blood_type']),
                    ),
                    _InfoRow(
                      icon: Icons.warning_amber_outlined,
                      label: 'Allergies',
                      value: _fmt(profile['allergies']),
                      isLast: true,
                    ),
                  ],
                  if (role == 'doctor') ...[
                    _InfoRow(
                      icon: Icons.biotech_outlined,
                      label: 'Specialization',
                      value: _fmt(profile['specialization']),
                    ),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'License Number',
                      value: _fmt(profile['license_number']),
                      isLast: true,
                    ),
                  ],
                ]),

                // Doctor-only additional section
                if (role == 'doctor' &&
                    ((profile['bio'] as String?)?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 20),
                  _SectionLabel('About'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onSurface.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      profile['bio'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Divider
                Container(
                  height: 1,
                  color: AppColors.surfaceContainer,
                ),
                const SizedBox(height: 24),

                // Switch Account
                _ActionButton(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Switch Account',
                  sublabel: 'Log in as a different user',
                  iconBg: AppColors.surfaceContainerLow,
                  iconColor: AppColors.onSurfaceVariant,
                  textColor: AppColors.onSurface,
                  onTap: onLogout, // same flow — clears token, goes to login
                ),
                const SizedBox(height: 12),

                // Log Out
                _ActionButton(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  sublabel: 'Sign out of your account',
                  iconBg: AppColors.error.withValues(alpha: 0.10),
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: onLogout,
                  showConfirm: true,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }
}

// ─────────────────────────────────────────────
// Hero banner with gradient
// ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String initials;
  final String displayName;
  final String roleLabel;

  const _HeroBanner({
    required this.initials,
    required this.displayName,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              // Avatar ring
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 3),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  roleLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info card with rows
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 66,
            endIndent: 0,
            color: AppColors.surfaceContainer,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action button (logout / switch account)
// ─────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconBg;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool showConfirm;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
    this.showConfirm = false,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (!showConfirm) {
      onTap();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text(
          'Log Out',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700, color: AppColors.onSurface),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
