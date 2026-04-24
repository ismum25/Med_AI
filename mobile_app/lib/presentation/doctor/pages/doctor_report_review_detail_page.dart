import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

/// Edit extracted OCR JSON, optional notes, open source file, submit verify.
class DoctorReportReviewDetailPage extends StatefulWidget {
  final String reportId;

  const DoctorReportReviewDetailPage({super.key, required this.reportId});

  @override
  State<DoctorReportReviewDetailPage> createState() =>
      _DoctorReportReviewDetailPageState();
}

class _DoctorReportReviewDetailPageState
    extends State<DoctorReportReviewDetailPage> {
  static const _metaKeys = [
    'test_name',
    'lab_name',
    'patient_name',
    'report_date',
    'doctor_name',
    'data_type',
  ];

  final Map<String, TextEditingController> _metaCtrls = {};
  final List<Map<String, TextEditingController>> _resultCtrls = [];
  late final TextEditingController _notesCtrl;
  TextEditingController? _rawJsonCtrl;

  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;
  bool _useRawJson = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _rawJsonCtrl?.dispose();
    for (final c in _metaCtrls.values) {
      c.dispose();
    }
    for (final row in _resultCtrls) {
      for (final c in row.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _clearEditors() {
    for (final c in _metaCtrls.values) {
      c.dispose();
    }
    _metaCtrls.clear();
    for (final row in _resultCtrls) {
      for (final c in row.values) {
        c.dispose();
      }
    }
    _resultCtrls.clear();
    _rawJsonCtrl?.dispose();
    _rawJsonCtrl = null;
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final client = sl<DioClient>();
      final res = await client.dio.get(ApiEndpoints.reportById(widget.reportId));
      if (!mounted) return;
      final map = Map<String, dynamic>.from(res.data as Map);
      _clearEditors();
      _report = map;
      _notesCtrl.text = (map['notes'] as String?) ?? '';

      final extracted = map['extracted_data'];
      if (extracted is Map<String, dynamic>) {
        final ext = Map<String, dynamic>.from(extracted);
        final structuredShape = ext.containsKey('results');
        _useRawJson = !structuredShape && ext.isNotEmpty;
        if (_useRawJson) {
          _rawJsonCtrl = TextEditingController(
            text: const JsonEncoder.withIndent('  ').convert(ext),
          );
        } else {
          for (final k in _metaKeys) {
            _metaCtrls[k] = TextEditingController(text: '${ext[k] ?? ''}');
          }
          final rawResults = ext['results'];
          if (rawResults is List) {
            for (final item in rawResults) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                _resultCtrls.add({
                  'parameter':
                      TextEditingController(text: '${m['parameter'] ?? ''}'),
                  'value': TextEditingController(text: '${m['value'] ?? ''}'),
                  'unit': TextEditingController(text: '${m['unit'] ?? ''}'),
                  'reference_range':
                      TextEditingController(text: '${m['reference_range'] ?? ''}'),
                  'flag': TextEditingController(text: '${m['flag'] ?? ''}'),
                });
              }
            }
          }
          if (_resultCtrls.isEmpty) {
            _resultCtrls.add(_emptyResultRow());
          }
        }
      } else {
        _useRawJson = false;
        for (final k in _metaKeys) {
          _metaCtrls[k] = TextEditingController();
        }
        _resultCtrls.add(_emptyResultRow());
      }

      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load report';
          _loading = false;
        });
      }
    }
  }

  Map<String, TextEditingController> _emptyResultRow() => {
        'parameter': TextEditingController(),
        'value': TextEditingController(),
        'unit': TextEditingController(),
        'reference_range': TextEditingController(),
        'flag': TextEditingController(),
      };

  Map<String, dynamic> _buildVerifyData() {
    if (_useRawJson && _rawJsonCtrl != null) {
      final parsed = jsonDecode(_rawJsonCtrl!.text);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Root JSON must be an object');
      }
      return Map<String, dynamic>.from(parsed);
    }

    final out = <String, dynamic>{};
    for (final e in _metaCtrls.entries) {
      final v = e.value.text.trim();
      if (v.isNotEmpty) {
        out[e.key] = v;
      }
    }
    final rows = <Map<String, dynamic>>[];
    for (final row in _resultCtrls) {
      rows.add({
        'parameter': row['parameter']!.text.trim(),
        'value': row['value']!.text.trim(),
        'unit': row['unit']!.text.trim().isEmpty ? null : row['unit']!.text.trim(),
        'reference_range': row['reference_range']!.text.trim().isEmpty
            ? null
            : row['reference_range']!.text.trim(),
        'flag': row['flag']!.text.trim().isEmpty ? null : row['flag']!.text.trim(),
      });
    }
    out['results'] = rows;
    return out;
  }

  Future<void> _openFile() async {
    try {
      final client = sl<DioClient>();
      final res =
          await client.dio.get(ApiEndpoints.reportDownload(widget.reportId));
      final url = (res.data as Map)['download_url'] as String?;
      if (url == null || url.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No download URL')),
        );
        return;
      }
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load download link')),
      );
    }
  }

  Future<void> _confirmVerify() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify report'),
        content: const Text(
          'Mark this report verified? This locks the extraction for downstream use.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _submitVerify();
  }

  Future<void> _submitVerify() async {
    Map<String, dynamic> data;
    try {
      data = _buildVerifyData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid data: $e')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = sl<DioClient>();
      await client.dio.patch(
        ApiEndpoints.verifyReport(widget.reportId),
        data: {
          'data': data,
          if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report verified'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? '${(e.response!.data as Map)['detail'] ?? e.message}'
          : e.message ?? 'Verify failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null || _report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Unknown error'),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final r = _report!;
    final title =
        (r['title'] as String?) ?? (r['file_name'] as String?) ?? 'Report';
    final type = (r['report_type'] as String?) ?? '';
    final createdAt = r['created_at'] as String?;
    final createdStr = createdAt != null
        ? DateFormat.yMMMd().add_jm().format(DateTime.parse(createdAt).toLocal())
        : '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Review report')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _submitting ? null : _confirmVerify,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            if (type.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  type.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            if (createdStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  createdStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    (r['ocr_status'] as String?) ?? '',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openFile,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open file'),
            ),
            const SizedBox(height: 24),
            Text(
              'Clinical notes',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Optional notes for this report',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Extracted data',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_useRawJson && _rawJsonCtrl != null)
              TextField(
                controller: _rawJsonCtrl,
                maxLines: 18,
                style: GoogleFonts.robotoMono(fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              )
            else ...[
              ..._metaKeys.map((k) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _metaCtrls[k],
                      decoration: InputDecoration(
                        labelText: k.replaceAll('_', ' '),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Results',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _resultCtrls.add(_emptyResultRow());
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add row'),
                  ),
                ],
              ),
              ...List.generate(_resultCtrls.length, (i) {
                final row = _resultCtrls[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Row ${i + 1}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            if (_resultCtrls.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () {
                                  setState(() {
                                    for (final c in row.values) {
                                      c.dispose();
                                    }
                                    _resultCtrls.removeAt(i);
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...[
                          'parameter',
                          'value',
                          'unit',
                          'reference_range',
                          'flag',
                        ].map((key) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextField(
                                controller: row[key],
                                decoration: InputDecoration(
                                  labelText: key.replaceAll('_', ' '),
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
