import 'package:flutter/material.dart';
import '../../appointments/pages/appointment_list_page.dart';
import '../../../core/theme/app_theme.dart';
import 'doctor_weekly_hours_page.dart';

/// Doctor "Schedule" tab: weekly availability editor + read-only appointment list.
class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<int>(
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.onSurfaceVariant;
              }),
            ),
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label: Text('Weekly hours'),
                icon: Icon(Icons.schedule_outlined, size: 18),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Appointments'),
                icon: Icon(Icons.calendar_month_outlined, size: 18),
              ),
            ],
            selected: {_segment},
            onSelectionChanged: (Set<int> next) {
              setState(() => _segment = next.first);
            },
          ),
        ),
        Expanded(
          child: _segment == 0
              ? const DoctorWeeklyHoursPage()
              : const AppointmentListPage(
                  showBookFab: false,
                  showFindDoctorSection: false,
                ),
        ),
      ],
    );
  }
}
