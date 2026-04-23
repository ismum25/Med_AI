import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
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
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final client = sl<DioClient>();
      final results = await Future.wait([
        client.dio.get(ApiEndpoints.appointments),
        client.dio.get(ApiEndpoints.reportsPendingReview),
      ]);
      if (mounted) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(results[0].data as List);
          _pendingReports = List<Map<String, dynamic>>.from(results[1].data as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load data'; _loading = false; });
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(_greeting(), style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    value: todayAppts.length,
                    label: 'Today',
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 24),
            Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (todayAppts.isEmpty)
              _EmptyState(
                icon: Icons.event_available_outlined,
                message: 'No appointments today',
              )
            else
              Column(
                children: List.generate(todayAppts.length, (i) {
                  final a = todayAppts[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < todayAppts.length - 1 ? 8 : 0),
                    child: _ScheduleCard(
                      appointment: a,
                      onTap: () => context.go(AppRoutes.doctorAppointments),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 24),
            Text('Reports Awaiting Review', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_pendingReports.isEmpty)
              _EmptyState(
                icon: Icons.assignment_turned_in_outlined,
                message: 'No reports awaiting review',
              )
            else
              Column(
                children: List.generate(
                  _pendingReports.length > 5 ? 5 : _pendingReports.length,
                  (i) {
                    final r = _pendingReports[i];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i < (_pendingReports.length > 5 ? 4 : _pendingReports.length - 1) ? 8 : 0),
                      child: _PendingReportCard(report: r),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            _AiAssistantCard(onTap: () => context.go(AppRoutes.doctorChat)),
            const SizedBox(height: 32),
          ],
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
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
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
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

  const _PendingReportCard({required this.report});

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
    final createdAt = report['created_at'] as String? ?? DateTime.now().toIso8601String();
    final displayType = type.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
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
              color: AppColors.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_outlined, color: AppColors.tertiary, size: 20),
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
                  displayType[0].toUpperCase() + displayType.substring(1),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            _timeAgo(createdAt),
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AI Assistant Card
// ─────────────────────────────────────────────
class _AiAssistantCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AiAssistantCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical AI Assistant',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ask clinical questions with patient context',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: GradientButton(label: 'Start', height: 38, onPressed: onTap),
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 24),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
