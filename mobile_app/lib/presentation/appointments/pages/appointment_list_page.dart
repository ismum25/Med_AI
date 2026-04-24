import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';

class AppointmentListPage extends StatelessWidget {
  /// When false (e.g. doctor shell), hides the patient "Book" FAB.
  final bool showBookFab;

  const AppointmentListPage({super.key, this.showBookFab = true});

  String get _appBarTitle => showBookFab ? 'My Appointments' : 'Appointments';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentBloc>()..add(LoadAppointments()),
      child: Scaffold(
        appBar: AppBar(title: Text(_appBarTitle)),
        body: BlocBuilder<AppointmentBloc, AppointmentState>(
          builder: (context, state) {
            if (state is AppointmentLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AppointmentError) {
              return Center(child: Text(state.message));
            }
            if (state is AppointmentsLoaded) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<AppointmentBloc>().add(LoadAppointments());
                  await context.read<AppointmentBloc>().stream.firstWhere(
                      (s) => s is AppointmentsLoaded || s is AppointmentError);
                },
                child: state.appointments.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 400,
                          child: Center(child: Text('No appointments found')),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: state.appointments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final appt = state.appointments[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_today,
                                color: appt.status == 'confirmed'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text(DateFormat('MMM dd, yyyy – hh:mm a')
                                  .format(appt.scheduledAt)),
                              subtitle:
                                  Text(appt.reason ?? 'Consultation'),
                              trailing: Chip(label: Text(appt.status)),
                            ),
                          );
                        },
                      ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: showBookFab
            ? FloatingActionButton.extended(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Book'),
              )
            : null,
      ),
    );
  }
}
