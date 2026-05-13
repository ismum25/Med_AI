import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messages = <_ChatMessage>[];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _sessions = <_ChatSessionSummary>[];
  bool _streaming = false;
  bool _bootstrapLoading = true;
  bool _sessionsLoading = false;
  bool _accessDenied = false;
  String? _sessionId;
  String _userRole = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final client = sl<DioClient>();
    try {
      final profileResponse = await client.dio.get(ApiEndpoints.me);
      final profile = profileResponse.data as Map<String, dynamic>;
      final role = (profile['role'] as String?)?.trim() ?? '';
      final displayName = (profile['full_name'] as String?)?.trim() ?? '';

      if (!mounted) return;
      setState(() {
        _userRole = role;
        _displayName = displayName;
        _accessDenied = role != 'patient';
      });

      if (_accessDenied) {
        if (mounted) setState(() => _bootstrapLoading = false);
        return;
      }

      final sessionsResponse = await client.dio.get(ApiEndpoints.chatSessions);
      final sessions =
          List<Map<String, dynamic>>.from(sessionsResponse.data as List)
              .map(_ChatSessionSummary.fromJson)
              .toList();

      if (!mounted) return;
      setState(() {
        _sessions
          ..clear()
          ..addAll(sessions);
        _bootstrapLoading = false;
      });

      if (_sessions.isNotEmpty) {
        await _loadSession(_sessions.first.id, refreshSessions: false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bootstrapLoading = false;
        _sessions.clear();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshSessions({String? selectSessionId}) async {
    final client = sl<DioClient>();
    try {
      final response = await client.dio.get(ApiEndpoints.chatSessions);
      final sessions = List<Map<String, dynamic>>.from(response.data as List)
          .map(_ChatSessionSummary.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _sessions
          ..clear()
          ..addAll(sessions);
      });

      if (selectSessionId != null) {
        await _loadSession(selectSessionId, refreshSessions: false);
      }
    } catch (_) {
      // Best-effort refresh.
    }
  }

  Future<void> _loadSession(String sessionId,
      {bool refreshSessions = true}) async {
    final client = sl<DioClient>();
    try {
      final response =
          await client.dio.get(ApiEndpoints.chatSession(sessionId));
      final data = response.data as Map<String, dynamic>;
      final messages =
          List<Map<String, dynamic>>.from(data['messages'] as List);

      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _messages
          ..clear()
          ..addAll(messages.map((item) {
            return _ChatMessage(
              role: item['role'] as String? ?? 'assistant',
              content: item['content'] as String? ?? '',
            );
          }));
      });

      if (refreshSessions) {
        await _refreshSessions(selectSessionId: sessionId);
      }
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open that conversation.')),
      );
    }
  }

  Future<String> _ensureSession(String firstMessage) async {
    if (_sessionId != null) return _sessionId!;
    final client = sl<DioClient>();
    final title = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}…'
        : firstMessage;
    final res = await client.dio.post(
      ApiEndpoints.chatSessions,
      data: {'title': title},
    );
    _sessionId = res.data['id'] as String;
    await _refreshSessions(selectSessionId: _sessionId);
    return _sessionId!;
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _streaming) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _messages.add(_ChatMessage(role: 'assistant', content: ''));
      _streaming = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final sessionId = await _ensureSession(text);
      final client = sl<DioClient>();

      final response = await client.dio.post(
        ApiEndpoints.chatMessages(sessionId),
        data: {'content': text},
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final ResponseBody body = response.data;
      String buffer = '';

      await for (final chunk
          in body.stream.cast<List<int>>().transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n\n')) {
          final idx = buffer.indexOf('\n\n');
          final event = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);
          for (final line in event.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            try {
              final data =
                  json.decode(line.substring(6)) as Map<String, dynamic>;
              if (data['type'] == 'text') {
                final content = data['content'] as String? ?? '';
                if (content.isNotEmpty && mounted) {
                  setState(() {
                    _messages.last.content += content;
                  });
                  _scrollToBottom();
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.last.content = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _streaming = false);
    }
  }

  Future<void> _startNewConversation() async {
    if (_streaming) return;
    setState(() {
      _messages.clear();
      _sessionId = null;
    });
  }

  Future<void> _showSessionsSheet() async {
    if (_streaming || _sessionsLoading) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sheetHeight = MediaQuery.of(context).size.height * 0.55;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Conversations',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _sessionsLoading
                            ? null
                            : () async {
                                setSheetState(() => _sessionsLoading = true);
                                await _refreshSessions();
                                if (mounted) {
                                  setState(() => _sessionsLoading = false);
                                }
                                setSheetState(() => _sessionsLoading = false);
                              },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No conversations yet.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: sheetHeight,
                      child: ListView.separated(
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final selected = session.id == _sessionId;
                          return Material(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                await _loadSession(session.id);
                              },
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(session.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                    )
                                  : const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.outline,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      return 'Today at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
    }
    return MaterialLocalizations.of(context).formatShortDate(local);
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_accessDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Health Assistant')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI chat is available for patients only.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userRole.isEmpty
                      ? 'Your account does not have access to this feature.'
                      : 'Current account: ${_userRole.toUpperCase()}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go(
                      _userRole == 'doctor'
                          ? AppRoutes.doctorDashboard
                          : AppRoutes.patientDashboard,
                    );
                  },
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _displayName.isEmpty
              ? 'AI Health Assistant'
              : 'AI Health Assistant - ${_displayName.split(' ').first}',
        ),
        actions: [
          IconButton(
            tooltip: 'Conversations',
            onPressed: _streaming ? null : _showSessionsSheet,
            icon: const Icon(Icons.history_rounded),
          ),
          if (_sessionId != null)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New conversation',
              onPressed: _streaming ? null : _startNewConversation,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyHint(sessionCount: _sessions.length)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      AppLayoutMetrics.bottomNavReserve(context),
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) =>
                        _MessageBubble(message: _messages[i]),
                  ),
          ),
          if (_streaming)
            LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          _InputBar(
            controller: _ctrl,
            enabled: !_streaming,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Data model (mutable for streaming append)
// ─────────────────────────────────────────────
class _ChatMessage {
  final String role;
  String content;
  _ChatMessage({required this.role, required this.content});
}

class _ChatSessionSummary {
  final String id;
  final String title;
  final DateTime createdAt;

  const _ChatSessionSummary({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory _ChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return _ChatSessionSummary(
      id: json['id'] as String,
      title: ((json['title'] as String?) ?? 'New Conversation').trim().isEmpty
          ? 'New Conversation'
          : ((json['title'] as String?) ?? 'New Conversation').trim(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: message.content.isEmpty && message.role == 'assistant'
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Thinking…',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.onSurfaceVariant)),
              ])
            : Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppColors.onSurface,
                  height: 1.5,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state hint
// ─────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final int sessionCount;
  const _EmptyHint({required this.sessionCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'AI Health Assistant',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sessionCount == 0
                  ? 'Start a new conversation about your health,\nsymptoms, or medical reports.'
                  : 'Select a previous conversation or start a new one.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  const _InputBar(
      {required this.controller, required this.enabled, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        AppLayoutMetrics.bottomNavReserve(context),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? (_) => onSend() : null,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask about your health…',
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: enabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: enabled ? AppColors.primaryGradient : null,
                color: enabled ? null : AppColors.outline,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                onPressed: enabled ? onSend : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
