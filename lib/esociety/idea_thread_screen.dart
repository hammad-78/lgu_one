import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/ventures/idea_team_panel.dart';
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

/// The student confirms a meeting, or asks for another time (with a note
/// saying when suits them). Used on the idea page and the student page.
Future<void> answerMeeting(
  BuildContext context,
  Idea idea, {
  required bool confirm,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  var note = '';
  if (!confirm) {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(
        title: 'Ask for another time',
        hint: 'Which days and times work for you?',
        action: 'Send request',
        required: true,
      ),
    );
    if (result == null) return;
    note = result;
  }
  try {
    await EsocietyService.instance.answerAppointment(
      idea,
      user,
      confirm: confirm,
      note: note,
    );
    if (context.mounted) {
      showFlushbar(
        context,
        confirm ? 'Meeting confirmed' : 'Request sent to the society',
        color: Colors.green.shade900,
      );
    }
  } catch (e) {
    if (context.mounted) {
      showFlushbar(context, 'Not sent. Try again.', color: Colors.red.shade900);
    }
  }
}

/// The meeting buttons a student sees: confirm, or ask for another time.
/// Empty once the meeting is past, cancelled or already answered both ways.
List<Widget> studentMeetingActions(BuildContext context, Idea idea) {
  final state = idea.appointmentState;
  if (idea.appointmentAt == null ||
      !idea.appointmentAt!.isAfter(DateTime.now()) ||
      state == AppointmentState.cancelled ||
      idea.status == IdeaStatus.withdrawn) {
    return const [];
  }
  return [
    if (state != AppointmentState.confirmed)
      MeetingAction(
        label: 'Confirm meeting',
        icon: Icons.check,
        primary: true,
        onPressed: () => answerMeeting(context, idea, confirm: true),
      ),
    if (state != AppointmentState.reschedule)
      MeetingAction(
        label: 'Ask for another time',
        icon: Icons.update,
        onPressed: () => answerMeeting(context, idea, confirm: false),
      ),
  ];
}

/// One idea and its conversation. Opened by the student who shared it, or by
/// a society member ([member] set), who also gets stage, review, meeting
/// and contact actions.
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
  bool _showIdea = false;

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

  void _error(String message) =>
      showFlushbar(context, message, color: Colors.red.shade900);

  void _done(String message) =>
      showFlushbar(context, message, color: Colors.green.shade900);

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
      if (mounted) {
        _error('Message not sent. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ─── Society actions ──────────────────────────────────────────────────────

  Future<void> _moveTo(Idea idea, IdeaStatus status, {String note = ''}) async {
    try {
      await _service.setStatus(idea, widget.member!, status, note: note);
      if (mounted) _done('Moved to ${status.label}');
    } catch (e) {
      if (mounted) _error('Stage not changed. Try again.');
    }
  }

  Future<void> _chooseStage(Idea idea) async {
    final result = await showDialog<(IdeaStatus, String)>(
      context: context,
      builder: (_) => _StageDialog(current: idea.status),
    );
    if (result == null || !mounted) return;
    await _moveTo(idea, result.$1, note: result.$2);
  }

  Future<void> _decline(Idea idea) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(
        title: 'Mark as not selected',
        hint: 'Tell the student why, and what could make it stronger',
        action: 'Mark not selected',
      ),
    );
    if (note == null || !mounted) return;
    await _moveTo(idea, IdeaStatus.declined, note: note);
  }

  Future<void> _writeReview(Idea idea) async {
    final result = await showReviewDialog(
      context,
      title: idea.hasReview ? 'Edit your review' : 'Review this idea',
      initialRating: idea.reviewRating ?? 0,
      initialText: idea.reviewText,
    );
    if (result == null || !mounted) return;
    try {
      await _service.saveReview(
        idea,
        widget.member!,
        rating: result.$1,
        text: result.$2,
      );
      if (mounted) _done('Review sent to ${idea.studentName}');
    } catch (e) {
      if (mounted) _error('Review not saved. Try again.');
    }
  }

  Future<void> _scheduleMeeting(Idea idea) async {
    final result = await showDialog<(DateTime, String, String)>(
      context: context,
      builder: (_) => _MeetingDialog(idea: idea),
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
      if (mounted) _done('Meeting invite sent to ${idea.studentName}');
    } catch (e) {
      if (mounted) _error('Invite not sent. Try again.');
    }
  }

  Future<void> _cancelMeeting(Idea idea) async {
    final yes = await _confirm(
      'Cancel this meeting?',
      '${idea.studentName} will see that it was cancelled.',
      'Cancel meeting',
      keep: 'Keep meeting',
    );
    if (!yes || !mounted) return;
    try {
      await _service.cancelAppointment(idea, widget.member!);
    } catch (e) {
      if (mounted) _error('Meeting not cancelled. Try again.');
    }
  }

  Future<void> _whatsApp(Idea idea) => openWhatsApp(
    idea.whatsapp!,
    'Hi ${idea.studentName}, this is ${widget.member?.name ?? ''} from the '
    'LGU Entrepreneurship Society, about your idea "${idea.title}".',
  );

  Future<void> _email(Idea idea) async {
    final uri = Uri(
      scheme: 'mailto',
      path: idea.studentEmail,
      queryParameters: {
        'subject': 'Your idea "${idea.title}" (LGU Entrepreneurship Society)',
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _error('No email app found on this device.');
    }
  }

  // ─── Student actions ──────────────────────────────────────────────────────

  Future<void> _answerMeeting(Idea idea, {required bool confirm}) =>
      answerMeeting(context, idea, confirm: confirm);

  Future<void> _withdraw(Idea idea) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final yes = await _confirm(
      'Withdraw this idea?',
      'The society will stop considering it. You can still read the '
          'conversation, but neither side can reply.',
      'Withdraw idea',
      keep: 'Keep idea',
    );
    if (!yes || !mounted) return;
    try {
      await _service.withdrawIdea(idea, user);
    } catch (e) {
      if (mounted) _error('Idea not withdrawn. Try again.');
    }
  }

  Future<bool> _confirm(
    String title,
    String body,
    String action, {
    required String keep,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(keep),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: EsTokens.of(context).clay,
              foregroundColor: Colors.white,
            ),
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
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snapshot.hasError
                            ? 'This idea could not be loaded. Check your '
                                  'connection and open it again.'
                            : 'This idea has been removed.',
                        textAlign: TextAlign.center,
                      ),
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
            title: Text(_isSociety ? 'Idea' : 'Your idea'),
            actions: [
              if (!_isSociety && idea.status != IdeaStatus.withdrawn)
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  onSelected: (_) => _withdraw(idea),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'withdraw',
                      child: Text('Withdraw idea'),
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
              _header(idea, showTrack: _isSociety),
              const SizedBox(height: 20),
              ..._panels(idea, showMeeting: _isSociety),
              _ideaToggle(idea),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _composerBar(idea),
      ],
    );
  }

  Widget _wideBody(Idea idea) {
    final t = EsTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 440,
          child: Scrollbar(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(32, 32, 28, 32),
              children: [
                _header(idea),
                const SizedBox(height: 24),
                ..._panels(idea),
                const SizedBox(height: 8),
                _ideaBody(idea),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, color: t.rule),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
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

  /// Title, who shared it, the stage track and the society's next step.
  Widget _header(Idea idea, {bool showTrack = true}) {
    final t = EsTokens.of(context);
    final shared = 'Shared ${relativeTime(idea.createdAt).toLowerCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(idea.title, style: EsType.title(t)),
        const SizedBox(height: 8),
        if (_isSociety)
          Row(
            children: [
              PersonAvatar(
                name: idea.studentName,
                photoUrl: idea.studentPhoto,
                radius: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    idea.studentName,
                    if (idea.studentLine.isNotEmpty) idea.studentLine,
                  ].join(', '),
                  style: EsType.small(t).copyWith(color: t.ink),
                ),
              ),
              Text(shared, style: EsType.small(t)),
            ],
          )
        else
          Text(shared, style: EsType.small(t)),
        if (showTrack) ...[
          const SizedBox(height: 22),
          StageTrack(status: idea.status, closedFrom: idea.closedFrom),
        ],
        if (_isSociety && idea.status != IdeaStatus.withdrawn) ...[
          const SizedBox(height: 20),
          _societyActions(idea),
        ],
      ],
    );
  }

  Widget _societyActions(Idea idea) {
    final next = idea.status.next;
    final hasPhone = idea.whatsapp != null && idea.whatsapp!.isNotEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (next != null)
          FilledButton(
            onPressed: () => _moveTo(idea, next),
            child: Text(idea.status.nextAction),
          ),
        TextButton(
          onPressed: () => _scheduleMeeting(idea),
          child: Text(
            idea.hasUpcomingAppointment
                ? 'Reschedule meeting'
                : 'Schedule meeting',
          ),
        ),
        TextButton(
          onPressed: () => _writeReview(idea),
          child: Text(idea.hasReview ? 'Edit review' : 'Write review'),
        ),
        PopupMenuButton<String>(
          tooltip: 'More actions',
          onSelected: (action) => switch (action) {
            'stage' => _chooseStage(idea),
            'decline' => _decline(idea),
            'whatsapp' => _whatsApp(idea),
            'email' => _email(idea),
            _ => null,
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'stage',
              child: Text('Move to a stage…'),
            ),
            if (idea.status != IdeaStatus.declined)
              const PopupMenuItem(
                value: 'decline',
                child: Text('Mark not selected'),
              ),
            const PopupMenuDivider(),
            if (hasPhone)
              const PopupMenuItem(
                value: 'whatsapp',
                child: Text('Message on WhatsApp'),
              ),
            if (idea.studentEmail.isNotEmpty)
              const PopupMenuItem(value: 'email', child: Text('Send an email')),
          ],
        ),
      ],
    );
  }

  /// Meeting and review, when there are any.
  List<Widget> _panels(Idea idea, {bool showMeeting = true}) {
    return [
      if (showMeeting && idea.appointmentAt != null) ...[
        MeetingBlock(
          idea: idea,
          forSociety: _isSociety,
          actions: _meetingActions(idea),
        ),
        const SizedBox(height: 20),
      ],
      if (idea.hasReview) ...[_review(idea), const SizedBox(height: 16)],
      IdeaTeamPanel(idea: idea, owner: _isSociety ? null : _owner(idea)),
    ];
  }

  /// The signed-in student, when they own [idea].
  User? _owner(Idea idea) {
    final me = StudentAuthService.instance.currentStudent;
    return me != null && me.uid == idea.studentUid ? me : null;
  }

  List<Widget> _meetingActions(Idea idea) {
    final state = idea.appointmentState;
    final upcoming = idea.appointmentAt!.isAfter(DateTime.now());
    if (!upcoming || state == AppointmentState.cancelled) return const [];
    if (_isSociety) {
      return [
        MeetingAction(
          label: 'Cancel meeting',
          icon: Icons.close,
          danger: true,
          onPressed: () => _cancelMeeting(idea),
        ),
      ];
    }
    if (idea.status == IdeaStatus.withdrawn) return const [];
    return [
      if (state != AppointmentState.confirmed)
        MeetingAction(
          label: 'Confirm meeting',
          icon: Icons.check,
          primary: true,
          onPressed: () => _answerMeeting(idea, confirm: true),
        ),
      if (state != AppointmentState.reschedule)
        MeetingAction(
          label: 'Ask for another time',
          icon: Icons.update,
          onPressed: () => _answerMeeting(idea, confirm: false),
        ),
    ];
  }

  Widget _review(Idea idea) {
    final t = EsTokens.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: t.moss, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSociety
                      ? 'Your society\'s review'
                      : 'The society\'s review',
                  style: EsType.heading(t).copyWith(fontSize: 15),
                ),
              ),
              if (idea.reviewRating != null) StarRow(idea.reviewRating!),
            ],
          ),
          if (idea.reviewText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(idea.reviewText, style: EsType.body(t)),
          ],
          const SizedBox(height: 6),
          Text(
            [
              if (idea.reviewedBy.isNotEmpty) idea.reviewedBy,
              if (idea.reviewedAt != null)
                kShortDateFormat.format(idea.reviewedAt!),
            ].join(', '),
            style: EsType.small(t),
          ),
        ],
      ),
    );
  }

  /// On phones the idea itself folds away so the conversation stays close.
  Widget _ideaToggle(Idea idea) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => setState(() => _showIdea = !_showIdea),
          icon: Icon(_showIdea ? Icons.expand_less : Icons.expand_more),
          label: Text(_showIdea ? 'Hide the idea' : 'Show the idea'),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _showIdea
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: _ideaBody(idea),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _ideaBody(Idea idea) {
    final t = EsTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EsSection(
          title: 'The problem',
          child: Text(idea.problem, style: EsType.body(t)),
        ),
        const SizedBox(height: 20),
        EsSection(
          title: 'The solution',
          child: Text(idea.solution, style: EsType.body(t)),
        ),
        const SizedBox(height: 20),
        FactList([
          ('For', idea.targetCustomers),
          ('Category', idea.category),
          ('Stage', idea.stage),
          (
            'Team',
            idea.teamSize == 1 ? 'Working alone' : '${idea.teamSize} people',
          ),
          ('Looking for', idea.helpNeeded.join(', ')),
          if (_isSociety) ('Email', idea.studentEmail),
          if (_isSociety && idea.whatsapp != null)
            ('WhatsApp', displayPakistaniPhone(idea.whatsapp!)),
        ]),
      ],
    );
  }

  Widget _thread(Idea idea, {required List<Widget> header}) {
    final t = EsTokens.of(context);
    return StreamBuilder<List<IdeaMessage>>(
      stream: _messageStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <IdeaMessage>[];
        if (messages.length != _lastMessageCount) {
          final first = _lastMessageCount == 0;
          _lastMessageCount = messages.length;
          // Phones open on the idea itself; only follow new messages.
          if (header.isEmpty || !first) _scrollToEndSoon(animate: !first);
        }
        return ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
            header.isEmpty ? 24 : 16,
            header.isEmpty ? 24 : 20,
            header.isEmpty ? 24 : 16,
            12,
          ),
          children: [
            // On phones the idea, its stage and the meeting sit in their own
            // tinted block, so the conversation clearly starts below it.
            if (header.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: header,
                ),
              ),
              const SizedBox(height: 28),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Conversation', style: EsType.heading(t)),
                const SizedBox(width: 8),
                if (messages.isNotEmpty)
                  Text(
                    messages.length == 1
                        ? '1 entry'
                        : '${messages.length} entries',
                    style: EsType.small(t),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: t.rule),
            const SizedBox(height: 12),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _isSociety
                      ? 'No replies yet. Ask a question, write a review or '
                            'schedule a meeting.'
                      : 'No replies yet. You can add details or ask the '
                            'society a question below.',
                  style: EsType.small(t),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _messageTile(IdeaMessage m) {
    final t = EsTokens.of(context);
    final time = m.createdAt == null ? '' : _stamp(m.createdAt!);
    final mine = m.fromSociety == _isSociety;
    final actor = mine ? 'You' : m.senderName;

    switch (m.kind) {
      case MessageKind.text:
        return _Bubble(message: m, mine: mine, time: time);
      case MessageKind.review:
        return _Event(
          time: time,
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$actor reviewed the idea',
                        style: EsType.small(
                          t,
                        ).copyWith(color: t.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (m.rating != null) StarRow(m.rating!, size: 15),
                  ],
                ),
                if (m.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SelectableText(
                    m.text,
                    style: EsType.body(t).copyWith(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        );
      case MessageKind.appointment:
        return _Event(
          time: time,
          child: SizedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$actor proposed a meeting', style: EsType.small(t)),
                      if (m.appointmentAt != null)
                        Text(
                          kAppointmentFormat.format(m.appointmentAt!),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                          ),
                        ),
                      if (m.appointmentPlace.isNotEmpty)
                        Text(m.appointmentPlace, style: EsType.small(t)),
                      if (m.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          m.text,
                          style: EsType.body(t).copyWith(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case MessageKind.appointmentReply:
        final state = AppointmentState.parse(m.appointmentReply);
        final what = switch (state) {
          AppointmentState.confirmed => '$actor confirmed the meeting',
          AppointmentState.reschedule => '$actor asked for another time',
          AppointmentState.cancelled => '$actor cancelled the meeting',
          _ => '$actor replied about the meeting',
        };
        // The stored text starts with the same sentence; keep only the note.
        final note = m.text.contains('\n')
            ? m.text.substring(m.text.indexOf('\n') + 1)
            : '';
        return _Note(
          text: what,
          note: note,
          time: time,
          color: state == null ? t.muted : t.appointmentColor(state),
        );
      case MessageKind.status:
        final status = IdeaStatus.parse(m.status);
        final what = switch (status) {
          IdeaStatus.submitted =>
            mine && !_isSociety
                ? 'You shared this idea'
                : '${m.senderName} shared this idea',
          IdeaStatus.withdrawn => '$actor withdrew this idea',
          _ => '$actor moved this to ${status.label}',
        };
        final note = m.text.contains('\n')
            ? m.text.substring(m.text.indexOf('\n') + 1)
            : '';
        return _Note(
          text: what,
          note: note,
          time: time,
          color: t.statusColor(status),
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
    final t = EsTokens.of(context);
    final theme = Theme.of(context);
    if (idea.status == IdeaStatus.withdrawn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: t.surface,
        child: Text(
          _isSociety
              ? 'The student withdrew this idea, so replies are closed.'
              : 'You withdrew this idea, so replies are closed.',
          textAlign: TextAlign.center,
          style: EsType.small(t),
        ),
      );
    }
    final canSend = _composer.text.trim().isNotEmpty && !_sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: t.rule)),
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
                    ? 'Reply to ${idea.studentName.split(' ').first}'
                    : 'Write to the society',
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: t.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
    final t = EsTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = mine
        ? (isDark ? const Color(0xFF14483A) : const Color(0xFFE9F3EB))
        : t.surface;
    final width = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (width * 0.8).clamp(0, 520)),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    // Accounts named after the society itself would read
                    // "E-Society, E-Society".
                    message.fromSociety &&
                            !message.senderName.toLowerCase().contains(
                              'society',
                            )
                        ? '${message.senderName}, E-Society'
                        : message.senderName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: t.moss,
                    ),
                  ),
                ),
              SelectableText(message.text, style: EsType.body(t)),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: EsType.small(t).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A non-chat entry (review, meeting) with its time underneath.
class _Event extends StatelessWidget {
  final Widget child;
  final String time;
  const _Event({required this.child, required this.time});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    time,
                    style: EsType.small(t).copyWith(fontSize: 11),
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

/// A one-line record of something that happened (stage change, meeting
/// reply), centered in the conversation, with an optional note from the
/// person who did it.
class _Note extends StatelessWidget {
  final String text;
  final String note;
  final String time;
  final Color color;
  const _Note({
    required this.text,
    required this.note,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: text,
                      style: TextStyle(
                        color: t.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: '   $time'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: EsType.small(t),
              ),
              if (note.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.trim(),
                  textAlign: TextAlign.center,
                  style: EsType.body(t).copyWith(fontSize: 14, color: t.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialogs ────────────────────────────────────────────────────────────────

class _StageDialog extends StatefulWidget {
  final IdeaStatus current;
  const _StageDialog({required this.current});

  @override
  State<_StageDialog> createState() => _StageDialogState();
}

class _StageDialogState extends State<_StageDialog> {
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
      title: const Text('Move to a stage'),
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
                      title: Text(s.label),
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
          onPressed: _status == widget.current
              ? null
              : () => Navigator.pop(context, (_status, _note.text.trim())),
          child: Text('Move to ${_status.label}'),
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
      setState(() => _error = 'Choose a rating from 1 to 5.');
      return;
    }
    if (_text.text.trim().isEmpty) {
      setState(() => _error = 'Add a few lines of feedback.');
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
            const SizedBox(height: 14),
            TextField(
              controller: _text,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'What works, what is risky, and what to do next',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: EsTokens.of(context).clay)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Send review')),
      ],
    );
  }
}

/// Star rating and feedback dialog, also used for collaborations.
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
class _MeetingDialog extends StatefulWidget {
  final Idea idea;
  const _MeetingDialog({required this.idea});

  @override
  State<_MeetingDialog> createState() => _MeetingDialogState();
}

class _MeetingDialogState extends State<_MeetingDialog> {
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
      setState(() => _error = 'Choose a date and a time.');
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
      setState(() => _error = 'That time has passed. Choose a later one.');
      return;
    }
    if (_place.text.trim().isEmpty) {
      setState(() => _error = 'Add a room or a meeting link.');
      return;
    }
    Navigator.pop(context, (at, _place.text.trim(), _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return AlertDialog(
      title: Text(
        widget.idea.hasUpcomingAppointment
            ? 'Reschedule meeting'
            : 'Schedule a meeting',
      ),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.idea.studentName} will be asked to confirm.',
              style: EsType.small(t),
            ),
            const SizedBox(height: 14),
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
                hintText: 'Room, or a Google Meet link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What to prepare (optional)',
                hintText: 'e.g. A 5-minute pitch and rough costs',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: t.clay)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Send invite')),
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
