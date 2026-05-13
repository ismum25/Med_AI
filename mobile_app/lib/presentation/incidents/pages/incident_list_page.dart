import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

class IncidentListPage extends StatefulWidget {
  const IncidentListPage({super.key});

  @override
  State<IncidentListPage> createState() => _IncidentListPageState();
}

class _IncidentListPageState extends State<IncidentListPage> {
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final client = sl<DioClient>();
      final res = await client.dio.get(ApiEndpoints.incidents);
      if (!mounted) return;
      setState(() {
        _incidents = List<Map<String, dynamic>>.from(res.data as List);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load incidents';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Incidents')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.uploadIncident),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: Text('Upload',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_incidents.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.medical_information_outlined,
                    size: 48, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No incidents yet',
                    style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Upload an injury photo to get an AI assessment',
                    style: GoogleFonts.inter(
                        color: AppColors.outline, fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _incidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final incident = _incidents[i];
          return _IncidentCard(
            incident: incident,
            onTap: () async {
              final id = incident['id']?.toString();
              if (id == null) return;
              await context.push(AppRoutes.patientIncidentDetail(id));
              if (mounted) _load();
            },
          );
        },
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback? onTap;
  const _IncidentCard({required this.incident, this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'analyzed':
        return AppColors.primary;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (incident['title'] as String?) ?? 'Incident';
    final injuryType = (incident['injury_type'] as String?) ?? 'unknown';
    final status = (incident['analysis_status'] as String?) ?? 'pending';
    final severity = (incident['severity'] as String?) ?? 'unknown';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
            _IncidentThumbnail(incidentId: incident['id']?.toString()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${injuryType.replaceAll('_', ' ').capitalize()} • ${severity.replaceAll('_', ' ').capitalize()}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').capitalize(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(status),
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

class _IncidentThumbnail extends StatelessWidget {
  final String? incidentId;
  const _IncidentThumbnail({this.incidentId});

  @override
  Widget build(BuildContext context) {
    if (incidentId == null) {
      return _placeholder();
    }
    return FutureBuilder<Uint8List?>(
      future: _loadBytes(context, incidentId!),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image:
                  DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
            ),
          );
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.healing_outlined,
            color: AppColors.primary, size: 22),
      );

  Future<Uint8List?> _loadBytes(BuildContext context, String id) async {
    try {
      final client = sl<DioClient>();
      final res = await client.dio.get(ApiEndpoints.incidentDownload(id),
          options: Options(responseType: ResponseType.bytes));
      return Uint8List.fromList(List<int>.from(res.data as List));
    } catch (_) {
      return null;
    }
  }
}

extension _Cap on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
