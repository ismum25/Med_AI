import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../injection_container.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});
  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _reasonCtrl = TextEditingController();
  final _doctorIdCtrl = TextEditingController();
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
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (context, state) {
            if (state is AppointmentBooked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment booked!'), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            } else if (state is AppointmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _doctorIdCtrl,
                    decoration: const InputDecoration(labelText: 'Doctor ID', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_selectedDateTime != null
                        ? DateFormat('MMM dd, yyyy – hh:mm a').format(_selectedDateTime!)
                        : 'Select date and time'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _pickDateTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonCtrl,
                    decoration: const InputDecoration(labelText: 'Reason for visit', prefixIcon: Icon(Icons.description)),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  if (state is AppointmentLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: () {
                        if (_doctorIdCtrl.text.isNotEmpty && _selectedDateTime != null) {
                          context.read<AppointmentBloc>().add(BookAppointment(
                            doctorId: _doctorIdCtrl.text.trim(),
                            scheduledAt: _selectedDateTime!,
                            reason: _reasonCtrl.text.isNotEmpty ? _reasonCtrl.text : null,
                          ));
                        }
                      },
                      child: const Text('Book Appointment'),
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
