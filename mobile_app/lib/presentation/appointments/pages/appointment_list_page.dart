import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/appointment.dart';
import '../../../domain/entities/doctor.dart';
import '../../../injection_container.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';
import '../cubit/doctor_discovery_cubit.dart';
import '../models/book_appointment_args.dart';

class AppointmentListPage extends StatefulWidget {
  final bool showBookFab;
  final bool showFindDoctorSection;

  const AppointmentListPage({
    super.key,
    this.showBookFab = true,
    this.showFindDoctorSection = true,
  });

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _findSectionKey = GlobalKey();
  String _searchQuery = '';

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<AppointmentEntity> _sortedAppointments(List<AppointmentEntity> raw) {
    final now = DateTime.now();
    final list = List<AppointmentEntity>.from(raw);
    list.sort((a, b) {
      final aUp = !a.scheduledAt.isBefore(now);
      final bUp = !b.scheduledAt.isBefore(now);
      if (aUp != bUp) return aUp ? -1 : 1;
      if (aUp) return a.scheduledAt.compareTo(b.scheduledAt);
      return b.scheduledAt.compareTo(a.scheduledAt);
    });
    return list;
  }

  void _scrollToFindDoctor() {
    final ctx = _findSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    }
  }

  String _experienceLine(DoctorListItemEntity d) {
    final y = d.yearsExperience;
    if (y == null || y <= 0) return 'Experience not listed';
    return '$y yrs exp.';
  }

  String _doctorInitials(String name) {
    final p = name.trim().split(RegExp(r'\s+'));
    if (p.isEmpty) return 'D';
    if (p.length == 1) return p[0].substring(0, 1).toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  List<DoctorListItemEntity> _filterDoctors(
    List<DoctorListItemEntity> doctors,
  ) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return doctors;
    return doctors.where((d) {
      final name = d.fullName.toLowerCase();
      final hosp = (d.hospital ?? '').toLowerCase();
      final spec = d.specialization.toLowerCase();
      return name.contains(q) || hosp.contains(q) || spec.contains(q);
    }).toList();
  }

  Future<void> _onRefresh(BuildContext context) async {
    context.read<AppointmentBloc>().add(LoadAppointments());
    final apptDone = context.read<AppointmentBloc>().stream.firstWhere(
          (s) => s is AppointmentsLoaded || s is AppointmentError,
        );
    if (widget.showFindDoctorSection) {
      await context.read<DoctorDiscoveryCubit>().load();
    }
    await apptDone;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFindDoctorSection) {
      return BlocProvider(
        create: (_) => sl<AppointmentBloc>()..add(LoadAppointments()),
        child: _buildScaffold(context),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AppointmentBloc>()..add(LoadAppointments())),
        BlocProvider(create: (_) => sl<DoctorDiscoveryCubit>()..load()),
      ],
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppColors.surfaceContainerLowest,
      ),
      floatingActionButton: widget.showBookFab && widget.showFindDoctorSection
          ? FloatingActionButton.extended(
              onPressed: _scrollToFindDoctor,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: BlocBuilder<AppointmentBloc, AppointmentState>(
        builder: (context, apptState) {
          if (!widget.showFindDoctorSection) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _onRefresh(context),
              child: _appointmentOnlyBody(context, apptState),
            );
          }

          return BlocBuilder<DoctorDiscoveryCubit, DoctorDiscoveryState>(
            builder: (context, docState) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _onRefresh(context),
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _yourAppointmentsSection(context, apptState),
                    ),
                    SliverToBoxAdapter(
                      child: _findDoctorSection(context, docState),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _appointmentOnlyBody(
    BuildContext context,
    AppointmentState apptState,
  ) {
    if (apptState is AppointmentLoading) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }
    if (apptState is AppointmentError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Center(child: Text(apptState.message)),
          ),
        ],
      );
    }
    if (apptState is AppointmentsLoaded) {
      final sorted = _sortedAppointments(apptState.appointments);
      if (sorted.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 400,
              child: Center(child: Text('No appointments yet')),
            ),
          ],
        );
      }
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _AppointmentTile(appointment: sorted[index]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _yourAppointmentsSection(
    BuildContext context,
    AppointmentState apptState,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your appointments',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (apptState is AppointmentLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (apptState is AppointmentError)
            Text(apptState.message, style: const TextStyle(color: AppColors.error))
          else if (apptState is AppointmentsLoaded) ...[
            if (apptState.appointments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'No bookings yet. Find a doctor below.',
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ..._sortedAppointments(apptState.appointments)
                  .take(8)
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AppointmentTile(appointment: a),
                      )),
          ],
        ],
      ),
    );
  }

  Widget _findDoctorSection(
    BuildContext context,
    DoctorDiscoveryState docState,
  ) {
    final selected = docState.selectedSpecialization;
    final chips = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) =>
              context.read<DoctorDiscoveryCubit>().selectSpecialization(null),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: GoogleFonts.inter(
            fontWeight: selected == null ? FontWeight.w600 : FontWeight.w500,
            color: selected == null ? AppColors.primary : AppColors.onSurface,
          ),
          side: BorderSide(
            color: selected == null ? AppColors.primary : AppColors.outline,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      ...docState.specializations.map(
        (s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(s),
            selected: selected == s,
            onSelected: (_) =>
                context.read<DoctorDiscoveryCubit>().selectSpecialization(s),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            labelStyle: GoogleFonts.inter(
              fontWeight: selected == s ? FontWeight.w600 : FontWeight.w500,
              color: selected == s ? AppColors.primary : AppColors.onSurface,
            ),
            side: BorderSide(
              color: selected == s ? AppColors.primary : AppColors.outline,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    ];

    return Padding(
      key: _findSectionKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find a doctor',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: chips,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: selected == null
                        ? 'Search doctors'
                        : 'Search in $selected',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('More filters coming soon')),
                    );
                  },
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.tune_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (docState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                docState.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          if (docState.loading && docState.doctors.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            ..._filterDoctors(docState.doctors).map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DoctorCard(
                  doctor: d,
                  experienceLine: _experienceLine(d),
                  initials: _doctorInitials(d.fullName),
                  onViewProfile: () => context.push(
                    AppRoutes.patientDoctorProfile(d.profileId),
                  ),
                  onBook: () => context.push(
                    AppRoutes.bookAppointment,
                    extra: BookAppointmentArgs(
                      doctorUserId: d.userId,
                      doctorProfileId: d.profileId,
                      doctorName: d.fullName,
                      specialization: d.specialization,
                    ),
                  ),
                ),
              ),
            ),
            if (!docState.loading && _filterDoctors(docState.doctors).isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No doctors match your search.',
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentEntity appointment;

  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final name = appointment.doctorFullName ?? 'Doctor';
    final spec = appointment.doctorSpecialization;
    final subtitle = spec != null && spec.isNotEmpty ? '$name · $spec' : name;

    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(
          Icons.calendar_today_rounded,
          color: appointment.status == 'confirmed'
              ? Colors.green.shade700
              : AppColors.primary,
        ),
        title: Text(
          DateFormat('MMM dd, yyyy · hh:mm a').format(appointment.scheduledAt.toLocal()),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: Text(appointment.status),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorListItemEntity doctor;
  final String experienceLine;
  final String initials;
  final VoidCallback onViewProfile;
  final VoidCallback onBook;

  const _DoctorCard({
    required this.doctor,
    required this.experienceLine,
    required this.initials,
    required this.onViewProfile,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = doctor.fullName.startsWith('Dr')
        ? doctor.fullName
        : 'Dr. ${doctor.fullName}';
    final location = (doctor.hospital ?? '').trim().isEmpty
        ? 'Location not listed'
        : doctor.hospital!;

    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doctor.specialization} · $experienceLine',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    Text(
                      '—',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'View profile',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onBook,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Book appointment',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
