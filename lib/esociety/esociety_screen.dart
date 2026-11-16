import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/account_screen.dart';
import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/esociety/idea_thread_screen.dart';
import 'package:lgu_one/esociety/share_idea_screen.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/web_layout.dart';

/// What each stage means to a student, shown under the stage track.
const List<String> kStageCaptions = [
  'You describe the problem and your solution.',
  'The society reads it and replies here.',
  'They meet you to dig into it.',
  'They back it with mentoring and support.',
];

/// Student side of the Entrepreneurship Society: the student's ideas, their
/// next meeting, and a way to share a new idea. Signed-out visitors see what
/// happens to an idea and are asked to sign in.
class EsocietyScreen extends StatelessWidget {
  const EsocietyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, _) {
        final student = StudentAuthService.instance.currentStudent;
        final wide = isWideWeb(context);
        return Scaffold(
          appBar: AppBar(title: const Text('Entrepreneurship Society')),
          body: SafeArea(
            child: student == null
                ? const _SignedOut()
                : _SignedIn(student: student, wide: wide),
          ),
        );
      },
    );
  }

  static Future<void> shareIdea(BuildContext context, User student) async {
    final shared = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ShareIdeaScreen(student: student)),
    );
    if (shared == true && context.mounted) {
      await showFlushbar(
        context,
        'Idea shared. The society\'s replies will appear here.',
        color: Colors.green.shade900,
        icon: Icons.check_circle_outline,
      );
    }
  }
}

// ─── Signed out ─────────────────────────────────────────────────────────────

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final wide = isWideWeb(context);
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 32 : 20,
        vertical: wide ? 48 : 28,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Got a startup idea?',
                  style: EsType.title(t).copyWith(fontSize: wide ? 28 : 24),
                ),
                const SizedBox(height: 10),
                Text(
                  'Share it with the LGU Entrepreneurship Society. Members '
                  'read every idea, reply to you in the app and set up '
                  'meetings for the promising ones.',
                  style: EsType.body(t).copyWith(color: t.muted),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                  child: const Text('Sign in with your LGU account'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only students with an email ending in .lgu.edu.pk can '
                  'share ideas.',
                  style: EsType.small(t),
                ),
                const SizedBox(height: 44),
                Text('What happens to your idea', style: EsType.heading(t)),
                const SizedBox(height: 16),
                const StageTrack(
                  status: IdeaStatus.accepted,
                  captions: kStageCaptions,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Signed in ──────────────────────────────────────────────────────────────

class _SignedIn extends StatefulWidget {
  final User student;
  final bool wide;
  const _SignedIn({required this.student, required this.wide});

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn> {
  late final Stream<List<Idea>> _stream = EsocietyService.instance.studentIdeas(
    widget.student.uid,
  );

  void _open(Idea idea) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => IdeaThreadScreen(ideaId: idea.id)),
  );

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return StreamBuilder<List<Idea>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Your ideas could not be loaded. Check your connection and '
                'open this page again.',
                textAlign: TextAlign.center,
                style: EsType.body(t),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final ideas = snapshot.data!;
        final meetings = ideas.where((i) => i.hasUpcomingAppointment).toList()
          ..sort((a, b) => a.appointmentAt!.compareTo(b.appointmentAt!));

        final header = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your ideas', style: EsType.title(t)),
                  const SizedBox(height: 4),
                  Text(
                    ideas.isEmpty
                        ? 'Nothing shared yet'
                        : '${ideas.length} shared with the society',
                    style: EsType.small(t),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () =>
                  EsocietyScreen.shareIdea(context, widget.student),
              child: const Text('Share an idea'),
            ),
          ],
        );

        final meetingSection = meetings.isEmpty
            ? null
            : EsSection(
                title: meetings.length == 1
                    ? 'Your next meeting'
                    : 'Your next meetings',
                child: Column(
                  children: [
                    for (final idea in meetings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MeetingBlock(
                          idea: idea,
                          forSociety: false,
                          contextLine: idea.title,
                          actions: studentMeetingActions(context, idea),
                          onTap: () => _open(idea),
                        ),
                      ),
                  ],
                ),
              );

        final list = ideas.isEmpty
            ? _EmptyIdeas(student: widget.student)
            : Column(
                children: [
                  for (final idea in ideas)
                    IdeaTile(
                      idea: idea,
                      unread: idea.unreadForStudent,
                      onTap: () => _open(idea),
                    ),
                ],
              );

        if (widget.wide) {
          return Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: WebConstrained(
                maxWidth: 960,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ideas.isNotEmpty)
                                Text('Ideas', style: EsType.heading(t)),
                              list,
                            ],
                          ),
                        ),
                        if (meetingSection != null) ...[
                          const SizedBox(width: 48),
                          Expanded(flex: 2, child: meetingSection),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            header,
            const SizedBox(height: 24),
            if (meetingSection != null) ...[
              meetingSection,
              const SizedBox(height: 28),
            ],
            if (ideas.isNotEmpty) Text('Ideas', style: EsType.heading(t)),
            list,
          ],
        );
      },
    );
  }
}

class _EmptyIdeas extends StatelessWidget {
  final User student;
  const _EmptyIdeas({required this.student});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share an idea and it will appear here with every reply, review '
          'and meeting date from the society.',
          style: EsType.body(t).copyWith(color: t.muted),
        ),
        const SizedBox(height: 32),
        Text('What happens to your idea', style: EsType.heading(t)),
        const SizedBox(height: 16),
        const StageTrack(status: IdeaStatus.accepted, captions: kStageCaptions),
      ],
    );
  }
}

// ─── List item ──────────────────────────────────────────────────────────────

/// One idea in a list: title, where it is on the track, and the latest
/// word in the conversation. [showStudent] adds who shared it (portal).
class IdeaTile extends StatelessWidget {
  final Idea idea;
  final bool unread;
  final bool showStudent;
  final VoidCallback onTap;
  const IdeaTile({
    super.key,
    required this.idea,
    required this.unread,
    required this.onTap,
    this.showStudent = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final fromSociety = idea.lastMessageBy == 'society';
    final who = fromSociety
        ? 'Society'
        : (showStudent ? idea.studentName.split(' ').first : 'You');

    final meta = <InlineSpan>[
      TextSpan(
        text: idea.status.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: t.statusColor(idea.status),
        ),
      ),
      if (showStudent) TextSpan(text: '   ${idea.studentName}'),
      if (idea.hasUpcomingAppointment)
        TextSpan(
          text: '   Meeting ${kShortDateFormat.format(idea.appointmentAt!)}',
          style: TextStyle(color: t.ink),
        ),
    ];

    return EsPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  idea.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EsType.heading(t).copyWith(
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                relativeTime(idea.lastActivityAt),
                style: EsType.small(t).copyWith(
                  fontSize: 12,
                  color: unread ? t.moss : t.muted,
                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: meta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EsType.small(t),
          ),
          if (idea.lastMessagePreview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$who: ${idea.lastMessagePreview}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EsType.body(
                      t,
                    ).copyWith(fontSize: 14, color: unread ? t.ink : t.muted),
                  ),
                ),
                if (unread) ...[const SizedBox(width: 10), const UnreadDot()],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
