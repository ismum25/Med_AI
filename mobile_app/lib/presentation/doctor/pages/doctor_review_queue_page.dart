import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

/// Inbox of reports awaiting doctor verification (`ocr_status == extracted`).
class DoctorReviewQueuePage extends StatefulWidget {
  const DoctorReviewQueuePage({super.key});

  @override
  State<DoctorReviewQueuePage> createState() => _DoctorReviewQueuePageState();
}

class _DoctorReviewQueuePageState extends State<DoctorReviewQueuePage> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showFullScreenSpinner = true}) async {
    if (!mounted) return;
    setState(() {
      _error = null;
      if (showFullScreenSpinner) _loading = true;
    });
    try {
      final client = sl<DioClient>();
      final res = await client.dio.get(ApiEndpoints.reportsPendingReview);
      if (!mounted) return;
      setState(() {
        _reports = List<Map<String, dynamic>>.from(res.data as List);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load reports';
          _loading = false;
        });
      }
    }
  }

  String _timeAgo(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _load(showFullScreenSpinner: false),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => _load(), child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _load(showFullScreenSpinner: false),
                  child: _reports.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                            Icon(
                              Icons.inbox_outlined,
                              size: 56,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'No reports waiting',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'OCR-extracted reports from your patients appear here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          itemCount: _reports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = _reports[i];
                            final id = r['id'] as String;
                            final title = (r['title'] as String?) ??
                                (r['file_name'] as String?) ??
                                'Medical report';
                            final type = (r['report_type'] as String?) ?? 'report';
                            final displayType =
                                type.replaceAll('_', ' ');
                            final createdAt =
                                r['created_at'] as String? ?? DateTime.now().toIso8601String();

                            return Material(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.push(AppRoutes.doctorReviewDetail(id)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.tertiary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.assignment_outlined,
                                          color: AppColors.tertiary,
                                          size: 20,
                                        ),
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
                                            Text(
                                              displayType.isNotEmpty
                                                  ? '${displayType[0].toUpperCase()}${displayType.substring(1)}'
                                                  : '',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(createdAt),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.outline,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
