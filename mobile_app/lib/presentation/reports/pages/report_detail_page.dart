import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/underline_text_field.dart';
import '../../../domain/usecases/update_report_usecase.dart';
import '../../../injection_container.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;
  bool _editing = false;
  bool _saving = false;
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = sl<DioClient>();
      final res = await client.dio.get(ApiEndpoints.reportById(widget.reportId));
      if (!mounted) return;
      setState(() {
        _report = Map<String, dynamic>.from(res.data as Map);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load report';
        _loading = false;
      });
    }
  }

  void _startEdit() {
    _titleCtrl.text = (_report?['title'] as String?) ?? '';
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    final newTitle = _titleCtrl.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await sl<UpdateReportUseCase>()(widget.reportId, title: newTitle);
      if (!mounted) return;
      setState(() {
        _report = updated;
        _editing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title updated'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    final r = _report!;
    final title = (r['title'] as String?) ?? (r['file_name'] as String?) ?? 'Medical Report';
    final type = (r['report_type'] as String?) ?? 'other';
    final status = (r['ocr_status'] as String?) ?? 'pending';
    final fileName = r['file_name'] as String?;
    final reportDate = r['report_date'] as String?;
    final createdAt = r['created_at'] as String?;
    final displayType = type.replaceAll('_', ' ');

    String createdStr = '';
    if (createdAt != null) {
      final dt = DateTime.parse(createdAt).toLocal();
      createdStr = DateFormat('MMM d, yyyy • h:mm a').format(dt);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titleSection(title),
                const SizedBox(height: 16),
                _statusPill(status),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _metaRow(Icons.category_outlined, 'Type',
                    displayType[0].toUpperCase() + displayType.substring(1)),
                if (reportDate != null && reportDate.isNotEmpty) ...[
                  _divider(),
                  _metaRow(Icons.event_outlined, 'Report date', reportDate),
                ],
                if (fileName != null) ...[
                  _divider(),
                  _metaRow(Icons.insert_drive_file_outlined, 'File', fileName),
                ],
                if (createdStr.isNotEmpty) ...[
                  _divider(),
                  _metaRow(Icons.schedule_outlined, 'Uploaded', createdStr),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleSection(String currentTitle) {
    if (_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UnderlineTextField(
            controller: _titleCtrl,
            label: 'Title',
            icon: Icons.title_rounded,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelEdit,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            currentTitle,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _startEdit,
          icon: const Icon(Icons.edit_outlined),
          color: AppColors.primary,
          tooltip: 'Edit title',
        ),
      ],
    );
  }

  Widget _statusPill(String status) {
    final color = switch (status) {
      'verified' => AppColors.primary,
      'extracted' => AppColors.tertiary,
      'processing' => Colors.orange,
      _ => AppColors.outline,
    };
    final label = switch (status) {
      'verified' => 'Verified',
      'extracted' => 'Extracted',
      'processing' => 'Processing',
      _ => 'Pending',
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: AppColors.outline.withValues(alpha: 0.2));
}
