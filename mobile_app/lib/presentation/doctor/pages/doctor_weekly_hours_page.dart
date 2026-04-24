import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

const _kDayKeys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const _kDayTitles = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
const _kBadge = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

/// Curated IANA zones for the picker (extend as needed).
const _kCommonTimezones = [
  'UTC',
  'Asia/Dhaka',
  'Asia/Kolkata',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Asia/Dubai',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Toronto',
  'Australia/Sydney',
  'Pacific/Auckland',
];

class _DayRange {
  final int startMin;
  final int endMin;

  _DayRange({required this.startMin, required this.endMin});

  String toApiString() =>
      '${_fmtHour(startMin)}-${_fmtHour(endMin)}';
}

String _fmtHour(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

_DayRange? _parseInterval(String s) {
  final parts = s.split('-');
  if (parts.length != 2) return null;
  final a = parts[0].trim().split(':');
  final b = parts[1].trim().split(':');
  if (a.length != 2 || b.length != 2) return null;
  final h1 = int.tryParse(a[0]);
  final m1 = int.tryParse(a[1]);
  final h2 = int.tryParse(b[0]);
  final m2 = int.tryParse(b[1]);
  if (h1 == null || m1 == null || h2 == null || m2 == null) return null;
  if (h1 > 23 ||
      m1 > 59 ||
      h2 > 23 ||
      m2 > 59 ||
      h1 < 0 ||
      m1 < 0 ||
      h2 < 0 ||
      m2 < 0) {
    return null;
  }
  final start = h1 * 60 + m1;
  final end = h2 * 60 + m2;
  if (end <= start) return null;
  return _DayRange(startMin: start, endMin: end);
}

class DoctorWeeklyHoursPage extends StatefulWidget {
  const DoctorWeeklyHoursPage({super.key});

  @override
  State<DoctorWeeklyHoursPage> createState() => _DoctorWeeklyHoursPageState();
}

class _DoctorWeeklyHoursPageState extends State<DoctorWeeklyHoursPage> {
  final Map<String, List<_DayRange>> _ranges = {
    for (final k in _kDayKeys) k: [],
  };

  String? _timezone;
  bool _loading = true;
  bool _dirty = false;
  String? _error;

  /// Server had `{}` / null — omit `available_slots` from PATCH until user edits intervals.
  bool _loadedLegacyUnset = true;
  bool _availabilityPayloadTouched = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _hasAnySlot =>
      _ranges.values.any((list) => list.isNotEmpty);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = sl<DioClient>();
      final res = await client.dio.get(ApiEndpoints.myProfile);
      final data = res.data as Map<String, dynamic>;
      final slots = data['available_slots'];
      final tz = data['availability_timezone'] as String?;
      setState(() {
        for (final k in _kDayKeys) {
          _ranges[k] = [];
        }
        if (slots is Map) {
          for (final k in _kDayKeys) {
            final raw = slots[k];
            if (raw is List) {
              for (final item in raw) {
                final r = _parseInterval(item.toString());
                if (r != null) {
                  _ranges[k]!.add(r);
                }
              }
            }
          }
        }
        _loadedLegacyUnset = slots == null || (slots is Map && slots.isEmpty);
        _availabilityPayloadTouched = false;
        _timezone = tz;
        _loading = false;
        _dirty = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not load availability';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_hasAnySlot &&
        (_timezone == null || _timezone!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a timezone before saving weekly hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final payload = <String, dynamic>{
      for (final k in _kDayKeys)
        k: _ranges[k]!.map((r) => r.toApiString()).toList(),
    };

    try {
      final client = sl<DioClient>();
      final body = <String, dynamic>{};
      if (!_loadedLegacyUnset || _availabilityPayloadTouched) {
        body['available_slots'] = payload;
      }
      if (_timezone != null && _timezone!.trim().isNotEmpty) {
        body['availability_timezone'] = _timezone;
      }

      await client.dio.patch(
        ApiEndpoints.doctorProfileUpdate,
        data: body,
      );
      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatRangeDisplay(_DayRange r) {
    final start = TimeOfDay(hour: r.startMin ~/ 60, minute: r.startMin % 60);
    final end = TimeOfDay(hour: r.endMin ~/ 60, minute: r.endMin % 60);
    final d1 = DateTime(2000, 1, 1, start.hour, start.minute);
    final d2 = DateTime(2000, 1, 1, end.hour, end.minute);
    final f = DateFormat.jm();
    return '${f.format(d1)} – ${f.format(d2)}';
  }

  Future<void> _pickTimezone() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: _kCommonTimezones.length,
          itemBuilder: (_, i) {
            final z = _kCommonTimezones[i];
            return ListTile(
              title: Text(z),
              onTap: () => Navigator.pop(ctx, z),
            );
          },
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _timezone = picked;
        _dirty = true;
      });
    }
  }

  Future<void> _editDay(int dayIndex) async {
    final key = _kDayKeys[dayIndex];
    final title = _kDayTitles[dayIndex];
    final working = List<_DayRange>.from(_ranges[key]!);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> pickRange(int idx, bool start) async {
              final r = working[idx];
              final initial = TimeOfDay(
                hour: (start ? r.startMin : r.endMin) ~/ 60,
                minute: (start ? r.startMin : r.endMin) % 60,
              );
              final t = await showTimePicker(
                context: ctx,
                initialTime: initial,
              );
              if (t == null) return;
              final mins = t.hour * 60 + t.minute;
              setSheet(() {
                if (start) {
                  working[idx] = _DayRange(
                    startMin: mins,
                    endMin: working[idx].endMin,
                  );
                } else {
                  working[idx] = _DayRange(
                    startMin: working[idx].startMin,
                    endMin: mins,
                  );
                }
              });
            }

            bool overlaps() {
              final sorted = [...working]..sort((a, b) => a.startMin.compareTo(b.startMin));
              for (var i = 0; i < sorted.length - 1; i++) {
                if (sorted[i].endMin > sorted[i + 1].startMin) {
                  return true;
                }
              }
              return false;
            }

            bool invalidLen(_DayRange r) => r.endMin - r.startMin < 15;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(working.length, (i) {
                      final r = working[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => pickRange(i, true),
                                  child: Text(_fmtHour(r.startMin)),
                                ),
                              ),
                              const Text('–'),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => pickRange(i, false),
                                  child: Text(_fmtHour(r.endMin)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setSheet(() => working.removeAt(i));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setSheet(() {
                          working.add(
                            _DayRange(startMin: 9 * 60, endMin: 17 * 60),
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add interval'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        for (final r in working) {
                          if (invalidLen(r)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Each interval must be at least 15 minutes',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        if (overlaps()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Intervals overlap'),
                            ),
                          );
                          return;
                        }
                        working.sort((a, b) => a.startMin.compareTo(b.startMin));
                        setState(() {
                          _ranges[key] = working;
                          _dirty = true;
                          _availabilityPayloadTouched = true;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly hours'),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Patients can request appointments within these windows.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public_outlined, color: AppColors.primary),
              title: Text(
                'Timezone',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _timezone ?? 'Not set (required if you add hours)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickTimezone,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...List.generate(7, (i) {
              final key = _kDayKeys[i];
              final dayRanges = _ranges[key]!;
              final title = _kDayTitles[i];
              final badge = _kBadge[i];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await _editDay(i);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.manrope(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: AppColors.outline,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (dayRanges.isEmpty)
                                  Text(
                                    'Unavailable — tap to add',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  )
                                else
                                  ...dayRanges.map(
                                    (r) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        _formatRangeDisplay(r),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
