import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/pakistani_phone_formatter.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/utils/whatsApp_support.dart';
import 'package:url_launcher/url_launcher.dart';

/// One idea and its conversation. Opened by the student who shared it, or by
/// a society member ([member] set), who also gets status, review,
/// appointment and contact actions.
class IdeaThreadScreen extends StatefulWidget {
  final String ideaId;
  final EsocietyMember? member;
  const IdeaThreadScreen({super.key, required this.ideaId, this.member});

  @override
  State<IdeaThreadScreen> createState() => _IdeaThreadScreenState();
}

class _IdeaThreadScreenState extends State<IdeaThreadScreen> {
  final _service = EsocietyService.instance;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  late final Stream<Idea?> _ideaStream = _service.idea(widget.ideaId);
  late final Stream<List<IdeaMessage>> _messageStream = _service.messages(
    widget.ideaId,
  );
  int _lastMessageCount = 0;
  bool _sending = false;
  bool _markingRead = false;

  bool get _isSociety => widget.member != null;

  @override
  void initState() {
    super.initState();
    _composer.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEndSoon({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  Future<void> _send(Idea idea) async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _sending = true);
    try {
      await _service.sendReply(
        ideaId: idea.id,
        fromSociety: _isSociety,
        senderUid: user.uid,
        senderName: _isSociety ? widget.member!.name : idea.studentName,
        text: text,
      );
      _composer.clear();
      _scrollToEndSoon();
    } catch (e) {
      if (mounted) _error('Could not send: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _error(String message) =>
      showFlushbar(context, message, color: Colors.red.shade900);

  void _ok(String message) =>
      showFlushbar(context, message, color: Colors.green.shade900);

  // ─── Society actions ──────────────────────────────────────────────────────

  Future<void> _changeStatus(Idea idea) async {
    final result = await showDialog<(IdeaStatus, String)>(
      context: context,
      builder: (_) => _StatusDialog(current: idea.status),
    );
    if (result == null || !mounted) return;
    try {
      await _service.setStatus(
        idea,
        widget.member!,
        result.$1,
        note: result.$2,
      );
      _ok('Status updated');
    } catch (e) {
      _error('Could not update status: $e');
    }
  }

  Future<void> _writeReview(Idea idea) async {
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (_) => _ReviewDialog(
        title: 'Review this idea',
        initialRating: idea.reviewRating ?? 0,
        initialText: idea.reviewText,
      ),
    );
    if (result == null || !mounted) return;
    try {
      await _service.saveReview(
        idea,
        widget.member!,
        rating: result.$1,
        text: result.$2,
      );
      _ok('Review shared with the student');
    } catch (e) {
      _error('Could not save review: $e');
    }
  }

  Future<void> _setAppointment(Idea idea) async {
    final result = await showDialog<(DateTime, String, String)>(
      context: context,
      builder: (_) => _AppointmentDialog(idea: idea),
    );
    if (result == null || !mounted) return;
    try {
      await _service.setAppointment(
        idea,
        widget.member!,
        at: result.$1,
        place: result.$2,
        note: result.$3,
      );
      _ok('Appointment sent to the student');
    } catch (e) {
      _error('Could not set appointment: $e');
    }
  }

  Future<void> _cancelAppointment(Idea idea) async {
    final yes = await _confirm(
      'Cancel appointment?',
      'The student will see that the appointment was cancelled.',
      'Cancel appointment',
    );
    if (!yes || !mounted) return;
    try {
      await _service.cancelAppointment(idea, widget.member!);
    } catch (e) {
      _error('Could not cancel: $e');
    }
  }

  Future<void> _whatsApp(Idea idea) => openWhatsApp(
    idea.whatsapp!,
    'Hi ${idea.studentName}, this is ${widget.member?.name ?? ''} from the '
    'LGU Entrepreneurship Society about your idea "${idea.title}".',
  );

  Future<void> _email(Idea idea) async {
    final uri = Uri(
      scheme: 'mailto',
      path: idea.studentEmail,
      queryParameters: {
        'subject': 'Your idea "${idea.title}" · LGU Entrepreneurship Society',
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _error('Could not open your email app');
    }
  }

  // ─── Student actions ──────────────────────────────────────────────────────

  Future<void> _answerAppointment(Idea idea, {required bool confirm}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    var note = '';
    if (!confirm) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => const _NoteDialog(
          title: 'Ask for another time',
          hint: 'Which days or times suit you?',
          action: 'Send',
          required: true,
        ),
      );
      if (result == null) return;
      note = result;
    }
    try {
      await _service.answerAppointment(
        idea,
        user,
        confirm: confirm,
        note: note,
      );
      if (mounted) {
        _ok(confirm ? 'Appointment confirmed' : 'Request sent to the society');
      }
    } catch (e) {
      if (mounted) _error('Could not send: $e');
    }
  }

  Future<void> _withdraw(Idea idea) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final yes = await _confirm(
      'Withdraw this idea?',
      'The society will no longer consider it. The conversation stays here '
          'for your records.',
      'Withdraw',
    );
    if (!yes || !mounted) return;
    try {
      await _service.withdrawIdea(idea, user);
    } catch (e) {
      if (mounted) _error('Could not withdraw: $e');
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Idea?>(
      stream: _ideaStream,
      builder: (context, snapshot) {
        final idea = snapshot.data;
        if (idea == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Idea')),
            body: Center(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : Text(
                      snapshot.hasError
                          ? 'Could not load this idea.'
                          : 'This idea no longer exists.',
                    ),
            ),
          );
        }
        final unread = _isSociety
            ? idea.unreadForSociety
            : idea.unreadForStudent;
        if (unread && !_markingRead) {
          _markingRead = true;
          _service
              .markRead(idea, asSociety: _isSociety)
              .whenComplete(() => _markingRead = false);
        }
        final wide = isWideWeb(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(idea.title, overflow: TextOverflow.ellipsis),
            actions: [
              if (!_isSociety && idea.status != IdeaStatus.withdrawn)
                PopupMenuButton<String>(
                  tooltip: 'More',
                  onSelected: (_) => _withdraw(idea),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'withdraw',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.undo),
                        title: Text('Withdraw idea'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SafeArea(child: wide ? _wideBody(idea) : _narrowBody(idea)),
        );
      },
    );
  }

  Widget _narrowBody(Idea idea) {
    return Column(
      children: [
        Expanded(
          child: _thread(
            idea,
            header: [
              _detailsCard(idea, collapsible: true),
              const SizedBox(height: 12),
              ..._statusPanels(idea),
            ],
          ),
        ),
        _composerBar(idea),
      ],
    );
  }

  Widget _wideBody(Idea idea) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 400,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
            children: [
              _detailsCard(idea, collapsible: false),
              const SizedBox(height: 14),
              ..._statusPanels(idea),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  Expanded(child: _thread(idea, header: const [])),
                  _composerBar(idea),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Status, society actions, review and appointment, in that order.
  List<Widget> _statusPanels(Idea idea) {
    return [
      if (_isSociety) ...[_societyActions(idea), const SizedBox(height: 12)],
      if (idea.appointmentAt != null) ...[
        AppointmentCard(idea: idea, actions: _appointmentActions(idea)),
        const SizedBox(height: 12),
      ],
      if (idea.hasReview) ...[_reviewPanel(idea), const SizedBox(height: 12)],
    ];
  }

  List<Widget> _appointmentActions(Idea idea) {
    final state = idea.appointmentState;
    final upcoming = idea.appointmentAt!.isAfter(DateTime.now());
    if (!upcoming || state == AppointmentState.cancelled) return const [];
    if (_isSociety) {
      return [
        OutlinedButton.icon(
          onPressed: () => _setAppointment(idea),
          icon: const Icon(Icons.edit_calendar, size: 18),
          label: const Text('Change'),
        ),
        TextButton.icon(
          onPressed: () => _cancelAppointment(idea),
          icon: const Icon(Icons.event_busy, size: 18),
          label: const Text('Cancel'),
        ),
      ];
    }
    if (idea.status == IdeaStatus.withdrawn) return const [];
    return [
      if (state != AppointmentState.confirmed)
        FilledButton.icon(
          onPressed: () => _answerAppointment(idea, confirm: true),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirm'),
        ),
      if (state != AppointmentState.reschedule)
        OutlinedButton.icon(
          onPressed: () => _answerAppointment(idea, confirm: false),
          icon: const Icon(Icons.schedule, size: 18),
          label: const Text('Ask for another time'),
        ),
    ];
  }

  Widget _reviewPanel(Idea idea) {
    final theme = Theme.of(context);
    return EsocietyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Society review',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (idea.reviewRating != null) StarRow(idea.reviewRating!),
            ],
          ),
          if (idea.reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              idea.reviewText,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.5),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            [
              if (idea.reviewedBy.isNotEmpty) idea.reviewedBy,
              if (idea.reviewedAt != null)
                kShortDateFormat.format(idea.reviewedAt!),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _societyActions(Idea idea) {
    final hasPhone = idea.whatsapp != null && idea.whatsapp!.isNotEmpty;
    return EsocietyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Society actions',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionChip(
                Icons.flag_outlined,
                'Status',
                () => _changeStatus(idea),
              ),
              _actionChip(
                Icons.rate_review_outlined,
                idea.hasReview ? 'Edit review' : 'Review',
                () => _writeReview(idea),
              ),
              _actionChip(
                Icons.event_available,
                idea.hasUpcomingAppointment ? 'Reschedule' : 'Appointment',
                () => _setAppointment(idea),
              ),
              if (hasPhone)
                _actionChip(
                  Icons.chat_outlined,
                  'WhatsApp',
                  () => _whatsApp(idea),
                ),
              if (idea.studentEmail.isNotEmpty)
                _actionChip(Icons.email_outlined, 'Email', () => _email(idea)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _detailsCard(Idea idea, {required bool collapsible}) {
    final theme = Theme.of(context);
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(name: idea.studentName, photoUrl: idea.studentPhoto),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                idea.studentName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                [
                  if (idea.studentLine.isNotEmpty) idea.studentLine,
                  'Shared ${relativeTime(idea.createdAt)}',
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IdeaStatusChip(idea.status, dense: true),
      ],
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _tag(Icons.category_outlined, idea.category),
            _tag(Icons.timeline, idea.stage),
            _tag(
              Icons.group_outlined,
              '${idea.teamSize} ${idea.teamSize == 1 ? 'person' : 'people'}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        IdeaField('Problem', idea.problem),
        IdeaField('Solution', idea.solution),
        IdeaField('Target customers', idea.targetCustomers),
        if (idea.helpNeeded.isNotEmpty) ...[
          Text(
            'LOOKING FOR',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: idea.helpNeeded
                .map(
                  (h) => Chip(
                    label: Text(h),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        if (_isSociety) ...[
          const Divider(height: 20),
          _contactLine(Icons.email_outlined, idea.studentEmail),
          if (idea.whatsapp != null)
            _contactLine(
              Icons.phone_outlined,
              displayPakistaniPhone(idea.whatsapp!),
            ),
        ],
      ],
    );

    if (!collapsible) {
      return EsocietyCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 14),
            Text(
              idea.title,
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 10),
            details,
          ],
        ),
      );
    }

    return EsocietyCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: header,
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tap to see the idea',
              style: theme.textTheme.bodySmall,
            ),
          ),
          children: [details],
        ),
      ),
    );
  }

  Widget _contactLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(text, style: const TextStyle(fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _thread(Idea idea, {required List<Widget> header}) {
    return StreamBuilder<List<IdeaMessage>>(
      stream: _messageStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <IdeaMessage>[];
        if (messages.length != _lastMessageCount) {
          final first = _lastMessageCount == 0;
          _lastMessageCount = messages.length;
          // Narrow screens open on the idea itself; only follow new messages.
          if (header.isEmpty || !first) _scrollToEndSoon(animate: !first);
        }
        return ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          children: [
            ...header,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Conversation',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting &&
                messages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            for (final m in messages) _messageTile(m),
            if (messages.length <= 1 &&
                snapshot.connectionState != ConnectionState.waiting)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _isSociety
                      ? 'Reply to the student, review the idea or set an '
                            'appointment.'
                      : 'The society will reply here. You can add details '
                            'or ask questions any time.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _messageTile(IdeaMessage m) {
    final theme = Theme.of(context);
    final time = m.createdAt == null ? '' : _stamp(m.createdAt!);
    final mine = m.fromSociety == _isSociety;

    switch (m.kind) {
      case MessageKind.text:
        return _Bubble(message: m, mine: mine, time: time);
      case MessageKind.review:
        return _EventCard(
          icon: Icons.rate_review_outlined,
          title: 'Review from ${m.senderName}',
          time: time,
          trailing: m.rating == null ? null : StarRow(m.rating!, size: 16),
          body: m.text,
        );
      case MessageKind.appointment:
        return _EventCard(
          icon: Icons.event_available,
          title: 'Appointment set by ${m.senderName}',
          time: time,
          highlight: m.appointmentAt == null
              ? null
              : kAppointmentFormat.format(m.appointmentAt!),
          subtitle: m.appointmentPlace,
          body: m.text,
        );
      case MessageKind.appointmentReply:
        final state = AppointmentState.parse(m.appointmentReply);
        return _EventPill(
          icon: switch (state) {
            AppointmentState.confirmed => Icons.event_available,
            AppointmentState.cancelled => Icons.event_busy,
            _ => Icons.schedule,
          },
          color: state?.color ?? theme.colorScheme.primary,
          text: '${m.senderName}: ${m.text}',
          time: time,
        );
      case MessageKind.status:
        final status = IdeaStatus.parse(m.status);
        return _EventPill(
          icon: status.icon,
          color: status.color,
          text: m.fromSociety ? '${m.text} · ${m.senderName}' : m.text,
          time: time,
        );
    }
  }

  String _stamp(DateTime t) {
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    return sameDay
        ? kTimeFormat.format(t)
        : '${kShortDateFormat.format(t)}, ${kTimeFormat.format(t)}';
  }

  Widget _composerBar(Idea idea) {
    final theme = Theme.of(context);
    if (idea.status == IdeaStatus.withdrawn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        child: Text(
          'This idea was withdrawn, so the conversation is closed.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    final canSend = _composer.text.trim().isNotEmpty && !_sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _composer,
              minLines: 1,
              maxLines: 5,
              maxLength: 1500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _isSociety
                    ? 'Reply to ${idea.studentName}…'
                    : 'Write to the society…',
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.primary.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: canSend ? () => _send(idea) : null,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

// ─── Thread pieces ──────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final IdeaMessage message;
  final bool mine;
  final String time;
  const _Bubble({
    required this.message,
    required this.mine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final bg = mine
        ? (isDark ? const Color(0xFF1C5A4D) : const Color(0xFFDCF3DD))
        : (isDark ? const Color(0xFF0B3D2E) : const Color(0xFFF2F4F3));
    final who = message.fromSociety
        ? '${message.senderName} · E-Society'
        : message.senderName;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78 > 560
              ? 560
              : MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            border: isDark
                ? Border.all(color: primary.withValues(alpha: 0.2))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    who,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              SelectableText(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String? highlight;
  final String? subtitle;
  final String body;
  final Widget? trailing;
  const _EventCard({
    required this.icon,
    required this.title,
    required this.time,
    required this.body,
    this.highlight,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (highlight != null) ...[
                const SizedBox(height: 8),
                Text(
                  highlight!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, style: theme.textTheme.bodySmall),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                SelectableText(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String time;
  const _EventPill({
    required this.icon,
    required this.color,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = isDark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: c),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$text  ·  $time',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dialogs ────────────────────────────────────────────────────────────────

class _StatusDialog extends StatefulWidget {
  final IdeaStatus current;
  const _StatusDialog({required this.current});

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late IdeaStatus _status = widget.current == IdeaStatus.withdrawn
      ? IdeaStatus.underReview
      : widget.current;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change status'),
      scrollable: true,
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<IdeaStatus>(
              groupValue: _status,
              onChanged: (v) => setState(() => _status = v ?? _status),
              child: Column(
                children: [
                  for (final s in IdeaStatus.societyChoices)
                    RadioListTile<IdeaStatus>(
                      value: s,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [IdeaStatusChip(s, dense: true)]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note to the student (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_status, _note.text.trim())),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

/// Star rating plus written feedback. Returns (rating, text).
class _ReviewDialog extends StatefulWidget {
  final String title;
  final int initialRating;
  final String initialText;
  const _ReviewDialog({
    required this.title,
    required this.initialRating,
    required this.initialText,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating = widget.initialRating;
  late final _text = TextEditingController(text: widget.initialText);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (_rating == 0) {
      setState(() => _error = 'Pick a rating');
      return;
    }
    if (_text.text.trim().isEmpty) {
      setState(() => _error = 'Write a few words of feedback');
      return;
    }
    Navigator.pop(context, (_rating, _text.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarPicker(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'Strengths, risks and what to do next',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Share review')),
      ],
    );
  }
}

/// Exposed for the collaborations tab of the portal.
Future<(int, String)?> showReviewDialog(
  BuildContext context, {
  required String title,
  int initialRating = 0,
  String initialText = '',
}) {
  return showDialog<(int, String)>(
    context: context,
    builder: (_) => _ReviewDialog(
      title: title,
      initialRating: initialRating,
      initialText: initialText,
    ),
  );
}

/// Date, time, place and a note. Returns (dateTime, place, note).
class _AppointmentDialog extends StatefulWidget {
  final Idea idea;
  const _AppointmentDialog({required this.idea});

  @override
  State<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<_AppointmentDialog> {
  DateTime? _date;
  TimeOfDay? _time;
  late final _place = TextEditingController(text: widget.idea.appointmentPlace);
  final _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.idea.appointmentAt;
    if (existing != null && existing.isAfter(DateTime.now())) {
      _date = DateTime(existing.year, existing.month, existing.day);
      _time = TimeOfDay.fromDateTime(existing);
    }
  }

  @override
  void dispose() {
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 11, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (_date == null || _time == null) {
      setState(() => _error = 'Pick a date and a time');
      return;
    }
    final at = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    if (at.isBefore(DateTime.now())) {
      setState(() => _error = 'That time has already passed');
      return;
    }
    if (_place.text.trim().isEmpty) {
      setState(() => _error = 'Say where the meeting is (room or online link)');
      return;
    }
    Navigator.pop(context, (at, _place.text.trim(), _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set appointment'),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('With ${widget.idea.studentName}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _date == null ? 'Date' : kShortDateFormat.format(_date!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      _time == null ? 'Time' : _time!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _place,
              decoration: const InputDecoration(
                labelText: 'Where',
                hintText: 'E-Society office, or a meeting link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'What to bring or prepare',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Send')),
      ],
    );
  }
}

class _NoteDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String action;
  final bool required;
  const _NoteDialog({
    required this.title,
    required this.hint,
    required this.action,
    this.required = false,
  });

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = !widget.required || _text.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _text,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: ok
              ? () => Navigator.pop(context, _text.text.trim())
              : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
