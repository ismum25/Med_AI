import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_panel.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../injection_container.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final client = sl<DioClient>();
      final results = await Future.wait([
        client.dio.get(ApiEndpoints.appointments),
        client.dio.get(ApiEndpoints.reports),
        client.dio.get(ApiEndpoints.incidents),
      ]);
      if (mounted) {
        setState(() {
          _appointments =
              List<Map<String, dynamic>>.from(results[0].data as List);
          _reports = List<Map<String, dynamic>>.from(results[1].data as List);
          _incidents = List<Map<String, dynamic>>.from(results[2].data as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Failed to load data';
          _loading = false;
        });
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Map<String, dynamic>> get _upcoming {
    final now = DateTime.now();
    return _appointments.where((a) {
      final at = DateTime.parse(a['scheduled_at'] as String).toLocal();
      final s = a['status'] as String;
      return at.isAfter(now) && s != 'cancelled' && s != 'completed';
    }).toList()
      ..sort((a, b) => DateTime.parse(a['scheduled_at'] as String)
          .compareTo(DateTime.parse(b['scheduled_at'] as String)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadData, child: const Text('Retry')),
        ]),
      );
    }

    final upcoming = _upcoming;
    final nextAppt = upcoming.isEmpty ? null : upcoming.first;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: AppLayoutMetrics.bottomNavReserve(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero greeting card ──────────────────────────────────
            RepaintBoundary(
              child: _HeroGreetingCard(greeting: _greeting()),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick actions ───────────────────────────────────
                  _QuickActionsRow(
                    actions: [
                      _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Book',
                        color: AppColors.primary,
                        onTap: () => context.push(AppRoutes.bookAppointment),
                      ),
                      _QuickAction(
                        icon: Icons.upload_file_outlined,
                        label: 'Upload',
                        color: AppColors.primaryContainer,
                        onTap: () => context.push(AppRoutes.uploadReport),
                      ),
                      _QuickAction(
                        icon: Icons.report_outlined,
                        label: 'Incident',
                        color: AppColors.accent,
                        onTap: () => context.push(AppRoutes.uploadIncident),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stat strip ──────────────────────────────────────
                  RepaintBoundary(
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: upcoming.length,
                            label: 'Upcoming',
                            icon: Icons.calendar_month_rounded,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            value: _reports.length,
                            label: 'Reports',
                            icon: Icons.folder_rounded,
                            iconColor: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            value: _incidents.length,
                            label: 'Incidents',
                            icon: Icons.healing_rounded,
                            iconColor: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Next appointment ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Next Appointment',
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.appointments),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _NextAppointmentCard(
                    appointment: nextAppt,
                    onBook: () => context.go(AppRoutes.appointments),
                    onView: () => context.go(AppRoutes.appointments),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent reports ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Reports',
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.reports),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_reports.isEmpty)
                    _EmptyBanner(
                      icon: Icons.folder_open_outlined,
                      message: 'No reports yet',
                      action: 'Upload',
                      onAction: () => context.push(AppRoutes.uploadReport),
                    )
                  else
                    _RecentReportsRow(
                      reports: _reports.take(3).toList(),
                      onTap: () => context.go(AppRoutes.reports),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero Greeting Card
// ─────────────────────────────────────────────
class _HeroGreetingCard extends StatelessWidget {
  final String greeting;

  static final _greetStyle = GoogleFonts.manrope(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );

  static final _subStyle = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    height: 1.4,
  );

  const _HeroGreetingCard({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: _greetStyle),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: _subStyle,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Your health overview",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Quick Actions Row
// ─────────────────────────────────────────────
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionsRow extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: a == actions.last ? 0 : 10,
            ),
            child: _QuickActionTile(action: a),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  static final _labelStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: action.color.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 22, color: action.color),
              const SizedBox(height: 6),
              Text(
                action.label,
                style: _labelStyle.copyWith(color: action.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Next Appointment Card
// ─────────────────────────────────────────────
class _NextAppointmentCard extends StatelessWidget {
  final Map<String, dynamic>? appointment;
  final VoidCallback onBook;
  final VoidCallback onView;

  const _NextAppointmentCard({
    required this.appointment,
    required this.onBook,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return SoftPanel(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No upcoming appointments',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Book one to get started',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onBook, child: const Text('Book')),
          ],
        ),
      );
    }

    final at = DateTime.parse(appointment!['scheduled_at'] as String).toLocal();
    final status = appointment!['status'] as String;
    final reason = (appointment!['reason'] as String?) ?? 'Consultation';

    return GestureDetector(
      onTap: onView,
      child: SoftPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(at),
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(at).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('hh:mm a, EEEE').format(at),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
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
    );
  }
}

// ─────────────────────────────────────────────
// Recent Reports Row
// ─────────────────────────────────────────────
class _RecentReportsRow extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final VoidCallback onTap;

  const _RecentReportsRow({required this.reports, required this.onTap});

  static final _titleStyle = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  IconData _icon(String? type) {
    switch (type) {
      case 'blood_test':
        return Icons.bloodtype_outlined;
      case 'xray':
        return Icons.image_outlined;
      case 'mri':
        return Icons.monitor_heart_outlined;
      case 'urine':
        return Icons.science_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'extracted':
        return 'Ready';
      case 'processing':
        return 'Processing';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final r = reports[i];
          final status = r['ocr_status'] as String? ?? 'pending';
          final isVerified = status == 'verified';
          final type = r['report_type'] as String?;
          final title = (r['title'] as String?) ??
              (r['file_name'] as String?) ??
              'Report';
          return GestureDetector(
            onTap: onTap,
            child: SoftPanel(
              width: 130,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icon(type), color: AppColors.primary, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: _titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.primary.withValues(alpha: 0.10)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isVerified
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty banner
// ─────────────────────────────────────────────
class _EmptyBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onAction;

  const _EmptyBanner({
    required this.icon,
    required this.message,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}
