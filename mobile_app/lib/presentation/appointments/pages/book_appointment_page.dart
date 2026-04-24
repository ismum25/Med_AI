import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';
import '../models/book_appointment_args.dart';

class BookAppointmentPage extends StatefulWidget {
  final BookAppointmentArgs? args;

  const BookAppointmentPage({super.key, this.args});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _reasonCtrl = TextEditingController();
  DateTime? _selectedDateTime;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return BlocProvider(
      create: (_) => sl<AppointmentBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Book appointment'),
          backgroundColor: AppColors.surfaceContainerLowest,
        ),
        body: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (context, state) {
            if (state is AppointmentBooked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment booked!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is AppointmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (args == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Pick a doctor from the list first.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            final loading = state is AppointmentLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: AppColors.surfaceContainerLowest,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppColors.outline.withValues(alpha: 0.35)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            args.doctorName.startsWith('Dr')
                                ? args.doctorName
                                : 'Dr. ${args.doctorName}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            args.specialization,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: Text(
                      _selectedDateTime != null
                          ? DateFormat('MMM dd, yyyy – hh:mm a')
                              .format(_selectedDateTime!)
                          : 'Date and time',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: loading ? null : _pickDateTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonCtrl,
                    enabled: !loading,
                    decoration: const InputDecoration(
                      labelText: 'Reason for visit',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),
                  if (loading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  else
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _selectedDateTime == null
                          ? null
                          : () {
                              context.read<AppointmentBloc>().add(
                                    BookAppointment(
                                      doctorId: args.doctorUserId,
                                      scheduledAt: _selectedDateTime!,
                                      reason: _reasonCtrl.text.isNotEmpty
                                          ? _reasonCtrl.text
                                          : null,
                                    ),
                                  );
                            },
                      child: const Text('Confirm booking'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
