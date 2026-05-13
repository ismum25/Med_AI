import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

class IncidentDetailPage extends StatefulWidget {
  final String incidentId;
  const IncidentDetailPage({super.key, required this.incidentId});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  Map<String, dynamic>? _incident;
  Uint8List? _imageBytes;
  bool _loading = true;
  String? _error;

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
      final client = sl<DioClient>();
      final incidentRes =
          await client.dio.get(ApiEndpoints.incidentById(widget.incidentId));
      final downloadRes = await client.dio.get(
        ApiEndpoints.incidentDownload(widget.incidentId),
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      setState(() {
        _incident = Map<String, dynamic>.from(incidentRes.data as Map);
        _imageBytes = Uint8List.fromList(downloadRes.data as List<int>);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load incident';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident Details'), actions: [
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Delete incident'),
                content: const Text(
                    'Are you sure you want to delete this incident?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.of(c).pop(true),
                      child: const Text('Delete')),
                ],
              ),
            );
            if (ok == true) {
              await _deleteIncident();
            }
          },
        )
      ]),
      body: _buildBody(),
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

    final i = _incident!;
    final title = (i['title'] as String?) ?? 'Incident';
    final status = (i['analysis_status'] as String?) ?? 'pending';
    final severity = (i['severity'] as String?) ?? 'unknown';
    final injuryType = (i['injury_type'] as String?) ?? 'unknown';
    final bodyArea = (i['body_area'] as String?) ?? 'unknown';
    final summary = (i['summary'] as String?) ?? '';
    final description = (i['description'] as String?) ?? '';
    final notes = (i['notes'] as String?) ?? '';
    final createdAt = i['created_at'] as String?;

    String createdStr = '';
    if (createdAt != null) {
      createdStr = DateFormat('MMM d, yyyy • h:mm a')
          .format(DateTime.parse(createdAt).toLocal());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_imageBytes != null && _imageBytes!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      size: 48, color: AppColors.onSurfaceVariant)),
            ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _pill(status),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              children: [
                _metaRow(Icons.warning_amber_rounded, 'Injury type',
                    _label(injuryType)),
                _divider(),
                _metaRow(
                    Icons.monitor_heart_outlined, 'Severity', _label(severity)),
                _divider(),
                _metaRow(
                    Icons.location_on_outlined, 'Body area', _label(bodyArea)),
                if (createdStr.isNotEmpty) ...[
                  _divider(),
                  _metaRow(Icons.schedule_outlined, 'Uploaded', createdStr),
                ],
              ],
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('AI Description',
                      style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    description.isNotEmpty ? description : summary,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your notes',
                      style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(notes,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteIncident() async {
    try {
      final client = sl<DioClient>();
      await client.dio.delete(ApiEndpoints.incidentById(widget.incidentId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Incident deleted')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete incident')));
    }
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _metaRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.onSurfaceVariant))),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface),
              ),
            ),
          ],
        ),
      );

  Widget _divider() => const Divider(height: 1);

  Widget _pill(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(status.capitalize(),
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      );

  String _label(String value) => value.replaceAll('_', ' ').capitalize();
}

extension _Cap on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
