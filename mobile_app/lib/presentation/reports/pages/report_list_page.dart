import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final client = sl<DioClient>();
      final res = await client.dio.get(ApiEndpoints.reports);
      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(res.data as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load reports'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.uploadReport),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_rounded),
        label: Text('Upload', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
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
          TextButton(onPressed: _loadReports, child: const Text('Retry')),
        ]),
      );
    }
    if (_reports.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadReports,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No reports yet', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Tap Upload to add your first report',
                    style: GoogleFonts.inter(color: AppColors.outline, fontSize: 13)),
              ]),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _ReportCard(
          report: _reports[i],
          onTap: () async {
            final id = _reports[i]['id']?.toString();
            if (id == null) return;
            await context.push(AppRoutes.patientReportDetail(id));
            if (mounted) _loadReports();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Report Card
// ─────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onTap;
  const _ReportCard({required this.report, this.onTap});

  static const _typeIcons = <String, IconData>{
    'blood_test': Icons.water_drop_outlined,
    'xray': Icons.radio_outlined,
    'mri': Icons.biotech_outlined,
    'ecg': Icons.monitor_heart_outlined,
    'urine_test': Icons.science_outlined,
    'prescription': Icons.receipt_long_outlined,
    'other': Icons.description_outlined,
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'verified': return AppColors.primary;
      case 'extracted': return AppColors.tertiary;
      case 'processing': return Colors.orange;
      default: return AppColors.outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified': return 'Verified';
      case 'extracted': return 'Extracted';
      case 'processing': return 'Processing';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (report['title'] as String?) ??
        (report['file_name'] as String?) ??
        'Medical Report';
    final type = (report['report_type'] as String?) ?? 'other';
    final status = (report['ocr_status'] as String?) ?? 'pending';
    final createdAt = report['created_at'] as String?;
    final displayType = type.replaceAll('_', ' ');
    final icon = _typeIcons[type] ?? Icons.description_outlined;
    final color = _statusColor(status);

    String dateStr = '';
    if (createdAt != null) {
      final dt = DateTime.parse(createdAt).toLocal();
      dateStr = DateFormat('MMM d, yyyy').format(dt);
    }

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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
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
                  displayType[0].toUpperCase() + displayType.substring(1),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: AppColors.outline)),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}
