import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/doctor.dart';
import '../../../domain/usecases/get_doctor_profile_usecase.dart';
import '../../../injection_container.dart';
import '../models/book_appointment_args.dart';

class DoctorProfilePage extends StatefulWidget {
  final String profileId;

  const DoctorProfilePage({super.key, required this.profileId});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  DoctorProfileEntity? _doctor;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await sl<GetDoctorProfileUseCase>()(widget.profileId);
      if (mounted) {
        setState(() {
          _doctor = doc;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFacingApiMessage(e);
          _loading = false;
        });
      }
    }
  }

  String _experienceLine(DoctorProfileEntity d) {
    final y = d.yearsExperience;
    if (y == null || y <= 0) return 'Experience not listed';
    return '$y yrs exp.';
  }

  String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+'));
    if (p.isEmpty) return 'D';
    if (p.length == 1) return p[0].substring(0, 1).toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  void _openBook(DoctorProfileEntity d) {
    context.push(
      AppRoutes.bookAppointment,
      extra: BookAppointmentArgs(
        doctorUserId: d.userId,
        doctorProfileId: d.id,
        doctorName: d.fullName,
        specialization: d.specialization,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Doctor profile'),
        backgroundColor: AppColors.surfaceContainerLowest,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _doctor == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                foregroundColor: AppColors.primary,
                                child: Text(
                                  _initials(_doctor!.fullName),
                                  style: GoogleFonts.manrope(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _doctor!.fullName.startsWith('Dr')
                                          ? _doctor!.fullName
                                          : 'Dr. ${_doctor!.fullName}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_doctor!.specialization} · ${_experienceLine(_doctor!)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    if (_doctor!.rating > 0) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 18,
                                            color: Colors.amber.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _doctor!.rating.toStringAsFixed(1),
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if ((_doctor!.hospital ?? '').isNotEmpty)
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: _doctor!.hospital!,
                            ),
                          if (_doctor!.consultationFee != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.payments_outlined,
                              label: 'Consultation fee',
                              value:
                                  '\$${_doctor!.consultationFee!.toStringAsFixed(0)}',
                            ),
                          ],
                          if ((_doctor!.bio ?? '').isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'About',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _doctor!.bio!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _openBook(_doctor!),
                            child: Text(
                              'Book appointment',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
