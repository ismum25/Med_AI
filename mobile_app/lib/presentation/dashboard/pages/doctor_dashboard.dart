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

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _pendingReports = [];
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
        client.dio.get(ApiEndpoints.reportsPendingReview),
      ]);
      if (mounted) {
        setState(() {
          _appointments =
              List<Map<String, dynamic>>.from(results[0].data as List);
          _pendingReports =
              List<Map<String, dynamic>>.from(results[1].data as List);
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

  List<Map<String, dynamic>> get _todayAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _appointments.where((a) {
      final at = DateTime.parse(a['scheduled_at'] as String).toLocal();
      final day = DateTime(at.year, at.month, at.day);
      return day == today && a['status'] != 'cancelled';
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

    final todayAppts = _todayAppointments;

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
                        icon: Icons.calendar_month_rounded,
                        label: 'Schedule',
                        color: AppColors.primary,
                        onTap: () => context.go(AppRoutes.doctorAppointments),
                      ),
                      _QuickAction(
                        icon: Icons.fact_check_outlined,
                        label: 'Review',
                        color: AppColors.tertiary,
                        onTap: () => context.go(AppRoutes.doctorReview),
                      ),
                      _QuickAction(
                        icon: Icons.people_alt_outlined,
                        label: 'Patients',
                        color: AppColors.accent,
                        onTap: () => context.go(AppRoutes.patients),
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
                            value: todayAppts.length,
                            label: 'Today',
                            icon: Icons.calendar_today_rounded,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            value: _pendingReports.length,
                            label: 'Pending Reviews',
                            icon: Icons.pending_actions_rounded,
                            iconColor: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Today's Schedule ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's Schedule",
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.doctorAppointments),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (todayAppts.isEmpty)
                    const _EmptyState(
                      icon: Icons.event_available_outlined,
                      message: 'No appointments today',
                    )
                  else
                    Column(
                      children: List.generate(todayAppts.length, (i) {
                        final a = todayAppts[i];
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: i < todayAppts.length - 1 ? 8 : 0),
                          child: _ScheduleCard(
                            appointment: a,
                            onTap: () =>
                                context.go(AppRoutes.doctorAppointments),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 24),

                  // ── Reports awaiting review ─────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Reports Awaiting Review',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (_pendingReports.isNotEmpty)
                        TextButton(
                          onPressed: () => context.go(AppRoutes.doctorReview),
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_pendingReports.isEmpty)
                    const _EmptyState(
                      icon: Icons.assignment_turned_in_outlined,
                      message: 'No reports awaiting review',
                    )
                  else
                    Column(
                      children: List.generate(
                        _pendingReports.length > 3 ? 3 : _pendingReports.length,
                        (i) {
                          final r = _pendingReports[i];
                          final n = _pendingReports.length > 3
                              ? 3
                              : _pendingReports.length;
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: i < n - 1 ? 8 : 0),
                            child: _PendingReportCard(
                              report: r,
                              onTap: () => context.push(
                                AppRoutes.doctorReviewDetail('${r['id']}'),
                              ),
                            ),
                          );
                        },
                      ),
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
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
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
                      Icons.medical_services_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Your daily overview",
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
// Quick Actions
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
// Schedule Card
// ─────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;

  const _ScheduleCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final at = DateTime.parse(appointment['scheduled_at'] as String).toLocal();
    final status = appointment['status'] as String;
    final reason = (appointment['reason'] as String?) ?? 'Consultation';
    final isConfirmed = status == 'confirmed';

    return SoftPanel(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('hh:mm a').format(at),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    '${appointment['duration_mins'] ?? 30} min',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isConfirmed
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isConfirmed ? AppColors.primary : AppColors.tertiary,
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
// Pending Report Card
// ─────────────────────────────────────────────
class _PendingReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _PendingReportCard({required this.report, required this.onTap});

  String _timeAgo(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final title = (report['title'] as String?) ??
        (report['file_name'] as String?) ??
        'Medical Report';
    final type = (report['report_type'] as String?) ?? 'Report';
    final createdAt =
        report['created_at'] as String? ?? DateTime.now().toIso8601String();
    final displayType = type.replaceAll('_', ' ');

    return SoftPanel(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: AppColors.tertiary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    displayType.isEmpty
                        ? ''
                        : displayType[0].toUpperCase() +
                            displayType.substring(1),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              _timeAgo(createdAt),
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.outline),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.outline, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
