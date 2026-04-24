import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
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
        client.dio.get(ApiEndpoints.reports),
      ]);
      if (mounted) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(results[0].data as List);
          _reports = List<Map<String, dynamic>>.from(results[1].data as List);
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

    final upcoming = _upcoming;
    final nextAppt = upcoming.isEmpty ? null : upcoming.first;

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
              "Here's your health overview",
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
                    value: upcoming.length,
                    label: 'Upcoming',
                    icon: Icons.calendar_month_rounded,
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    value: _reports.length,
                    label: 'Reports',
                    icon: Icons.folder_rounded,
                    iconColor: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Next Appointment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _NextAppointmentCard(
              appointment: nextAppt,
              onBook: () => context.go(AppRoutes.appointments),
              onView: () => context.go(AppRoutes.appointments),
            ),
            const SizedBox(height: 24),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.search_rounded,
                    label: 'Find a Doctor',
                    onTap: () => context.go(AppRoutes.appointments),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_rounded,
                    label: 'Book Appointment',
                    onTap: () => context.go(AppRoutes.appointments),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Reports', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.go(AppRoutes.reports),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 32),
          ],
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
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
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
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
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
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
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
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('hh:mm a, EEEE').format(at),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
// Quick Action Card
// ─────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
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
// Recent Reports Row
// ─────────────────────────────────────────────
class _RecentReportsRow extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final VoidCallback onTap;

  const _RecentReportsRow({required this.reports, required this.onTap});

  IconData _icon(String? type) {
    switch (type) {
      case 'blood_test': return Icons.bloodtype_outlined;
      case 'xray': return Icons.image_outlined;
      case 'mri': return Icons.monitor_heart_outlined;
      case 'urine': return Icons.science_outlined;
      default: return Icons.description_outlined;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified': return 'Verified';
      case 'extracted': return 'Ready';
      case 'processing': return 'Processing';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icon(type), color: AppColors.primary, size: 22),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        color: isVerified ? AppColors.primary : AppColors.onSurfaceVariant,
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
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}
