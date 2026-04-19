import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/stat_card.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Greeting + date
          Text(
            _greeting(),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _formattedDate(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: 4,
                  label: 'Today',
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: 3,
                  label: 'Pending Reviews',
                  icon: Icons.pending_actions_rounded,
                  iconColor: AppColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Today's Schedule
          Text("Today's Schedule",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _TodayScheduleList(
              onTap: () => context.go(AppRoutes.doctorAppointments)),
          const SizedBox(height: 24),
          // Reports awaiting review
          Text('Reports Awaiting Review',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _PendingReportsList(),
          const SizedBox(height: 24),
          // AI Assistant glass card
          _AiAssistantCard(
              onTap: () => context.go(AppRoutes.doctorChat)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TodayScheduleList extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayScheduleList({required this.onTap});

  static final _appointments = [
    _ApptItem('09:00', 'Sarah Johnson', 'General Checkup', 'Confirmed'),
    _ApptItem('10:30', 'Mike Chen', 'Follow-up', 'Pending'),
    _ApptItem('14:00', 'Emma Davis', 'Consultation', 'Confirmed'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_appointments.isEmpty) {
      return _EmptyState(
        icon: Icons.event_available_outlined,
        message: 'No appointments today',
      );
    }
    return Column(
      children: List.generate(_appointments.length, (i) {
        final item = _appointments[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < _appointments.length - 1 ? 8 : 0),
          child: _ScheduleCard(item: item, onTap: onTap),
        );
      }),
    );
  }
}

class _ApptItem {
  final String time;
  final String patient;
  final String reason;
  final String status;
  const _ApptItem(this.time, this.patient, this.reason, this.status);
}

class _ScheduleCard extends StatelessWidget {
  final _ApptItem item;
  final VoidCallback onTap;
  const _ScheduleCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = item.status == 'Confirmed';
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
            // Time chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.patient,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    item.reason,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isConfirmed
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isConfirmed
                      ? AppColors.primary
                      : AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingReportsList extends StatelessWidget {
  static final _reports = [
    ('Sarah Johnson', 'Blood Panel', '2h ago'),
    ('Mike Chen', 'Chest X-Ray', '5h ago'),
    ('Emma Davis', 'MRI Scan', 'Yesterday'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_reports.length, (i) {
        final (patient, type, time) = _reports[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < _reports.length - 1 ? 8 : 0),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        type,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

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
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 26,
                ),
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
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: GradientButton(
                  label: 'Start',
                  height: 38,
                  onPressed: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
