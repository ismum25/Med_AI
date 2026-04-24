import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/appointment_slot.dart';
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
  DateTime? _selectedDate;
  List<AppointmentSlotEntity> _slots = const [];
  DateTime? _selectedSlotUtc;
  int _slotDurationMins = 30;

  String _slotRangeLabel(AppointmentSlotEntity slot) {
    final start = slot.startAtUtc.toLocal();
    final end = start.add(Duration(minutes: _slotDurationMins));
    final f = DateFormat('hh:mm a');
    return '${f.format(start)} - ${f.format(end)}';
  }

  Future<void> _pickDate(BuildContext context, BookAppointmentArgs args) async {
    final bloc = context.read<AppointmentBloc>();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day).add(
        const Duration(days: 90),
      ),
    );
    if (date == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedSlotUtc = null;
      _slots = const [];
    });
    bloc.add(
      LoadDoctorSlots(doctorUserId: args.doctorUserId, date: _selectedDate!),
    );
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
            } else if (state is DoctorSlotsLoaded) {
              setState(() {
                _slots = state.payload.slots;
                _slotDurationMins = state.payload.slotDurationMins;
                if (_selectedSlotUtc != null &&
                    !_slots.any((s) => s.startAtUtc == _selectedSlotUtc)) {
                  _selectedSlotUtc = null;
                }
              });
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

            final bookingLoading = state is AppointmentLoading;
            final slotLoading = state is DoctorSlotsLoading;
            final hasPickedDate = _selectedDate != null;

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
                      hasPickedDate
                          ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                          : 'Pick date',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: bookingLoading
                        ? null
                        : () => _pickDate(context, args),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasPickedDate)
                    Text(
                      'Select a date to see available slots.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    )
                  else if (slotLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (_slots.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'No slots available for this date.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots
                          .map(
                            (slot) => ChoiceChip(
                              label: Text(_slotRangeLabel(slot)),
                              selected: _selectedSlotUtc == slot.startAtUtc,
                              onSelected: bookingLoading
                                  ? null
                                  : (_) => setState(
                                        () => _selectedSlotUtc = slot.startAtUtc,
                                      ),
                              selectedColor: AppColors.primary.withValues(alpha: 0.16),
                              labelStyle: TextStyle(
                                color: _selectedSlotUtc == slot.startAtUtc
                                    ? AppColors.primary
                                    : AppColors.onSurface,
                                fontWeight: _selectedSlotUtc == slot.startAtUtc
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonCtrl,
                    enabled: !bookingLoading,
                    decoration: const InputDecoration(
                      labelText: 'Reason for visit',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),
                  if (bookingLoading)
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
                      onPressed: _selectedSlotUtc == null
                          ? null
                          : () {
                              context.read<AppointmentBloc>().add(
                                    BookAppointment(
                                      doctorId: args.doctorUserId,
                                      scheduledAt: _selectedSlotUtc!,
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
