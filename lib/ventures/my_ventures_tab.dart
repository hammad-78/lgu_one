import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/account_screen.dart';
import 'package:lgu_one/collaboration/collab_actions.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/esociety/meeting_time_dialog.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/ventures/collab_post.dart';
import 'package:lgu_one/ventures/explore_tab.dart';

/// The student's own ventures: ideas sent to the society with their meeting
/// times, and their posts on the board. Signed-out visitors are asked to
/// sign in.
class MyVenturesTab extends StatelessWidget {
  final User? student;
  const MyVenturesTab({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;
    // Keyed by uid so a different account starts fresh streams.
    return s == null
        ? const _SignedOut()
        : _SignedIn(key: ValueKey(s.uid), student: s);
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Got a startup idea?', style: EsType.title(t)),
                const SizedBox(height: 10),
                Text(
                  'Post it to find teammates, and send it to the LGU '
                  'Entrepreneurship Society to get a meeting with them.',
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignedIn extends StatefulWidget {
  final User student;
  const _SignedIn({super.key, required this.student});

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<Idea>> _ideas = EsocietyService.instance.studentIdeas(
    widget.student.uid,
  );
  late final Stream<List<CollabPost>> _posts = CollabBoard.postsBy(
    widget.student.uid,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = EsTokens.of(context);
    return StreamBuilder<List<Idea>>(
      stream: _ideas,
      builder: (context, ideaSnap) => StreamBuilder<List<CollabPost>>(
        stream: _posts,
        builder: (context, postSnap) {
          if (ideaSnap.hasError || postSnap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Your ventures could not be loaded. Check your connection '
                  'and open this page again.',
                  textAlign: TextAlign.center,
                  style: EsType.body(t),
                ),
              ),
            );
          }
          if (!ideaSnap.hasData || !postSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _content(ideaSnap.data!, postSnap.data!, t);
        },
      ),
    );
  }

  Widget _content(List<Idea> ideas, List<CollabPost> posts, EsTokens t) {
    final active = ideas.where((i) => !i.isPast).toList();
    final past = ideas.where((i) => i.isPast).toList();

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text('Your ventures', style: EsType.title(t))),
        FilledButton(
          onPressed: () => CollabActions.startCreate(context),
          child: const Text('Share an idea'),
        ),
      ],
    );

    Widget muted(String text) => Text(
      text,
      style: EsType.body(t).copyWith(fontSize: 14, color: t.muted),
    );

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isWideWeb(context) ? 32 : 20,
        vertical: 24,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 24),
                EsSection(
                  title: 'With the E-Society',
                  child: active.isEmpty
                      ? muted(
                          'Tick "Send to the Entrepreneurship Society" when '
                          'you share an idea, and their meeting time shows '
                          'up here.',
                        )
                      : Column(
                          children: [
                            for (final i in active) _StudentIdeaCard(idea: i),
                          ],
                        ),
                ),
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  EsSection(
                    title: 'Past',
                    child: Column(
                      children: [
                        for (final i in past) _StudentIdeaCard(idea: i),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                EsSection(
                  title: 'Your posts',
                  child: posts.isEmpty
                      ? muted(
                          'Ideas you share go on the board once an admin '
                          'approves them.',
                        )
                      : Column(
                          children: [
                            for (final p in posts)
                              CollabPostTile(post: p, showStatus: true),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// An idea the student sent: its meeting time and, while it is active, a
/// way to ask for another time.
class _StudentIdeaCard extends StatelessWidget {
  final Idea idea;
  const _StudentIdeaCard({required this.idea});

  Future<void> _request(BuildContext context) async {
    final picked = await showMeetingTimeDialog(
      context,
      title: 'Request another time',
      textLabel: 'Note for the society (optional)',
      confirmLabel: 'Send request',
      initial: idea.requestedAt,
      initialText: idea.requestNote,
    );
    if (picked == null) return;
    try {
      await EsocietyService.instance.requestTime(idea, picked.$1, picked.$2);
      if (context.mounted) {
        await showFlushbar(
          context,
          'Request sent. The meeting moves once the society approves it.',
          color: Colors.green.shade900,
          icon: Icons.check_circle_outline,
        );
      }
    } catch (_) {
      if (context.mounted) {
        await showFlushbar(
          context,
          'Could not send the request. Try again.',
          color: Colors.red.shade900,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final meeting = idea.meetingAt;
    final strong = idea.isPast ? t.muted : t.ink;

    final String meetingLine;
    if (meeting == null) {
      meetingLine = idea.deactivated
          ? 'Closed by the society'
          : 'The society will send you a meeting time';
    } else {
      meetingLine = [
        '${idea.meetingPassed ? 'Met' : 'Meeting'} ${kMeetingFormat.format(meeting)}',
        if (idea.meetingPlace.isNotEmpty) idea.meetingPlace,
      ].join(' · ');
    }

    return EsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(idea.title, style: EsType.heading(t).copyWith(color: strong)),
          const SizedBox(height: 4),
          Text(
            meetingLine,
            style: EsType.body(t).copyWith(
              fontSize: 14,
              fontWeight: meeting == null ? FontWeight.w400 : FontWeight.w600,
              color: meeting == null || idea.isPast ? t.muted : t.moss,
            ),
          ),
          if (idea.requestedAt != null && !idea.deactivated) ...[
            const SizedBox(height: 2),
            Text(
              'You asked for ${kMeetingFormat.format(idea.requestedAt!)}',
              style: EsType.small(t),
            ),
          ],
          if (idea.hasUpcomingMeeting) ...[
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: t.moss,
                backgroundColor: t.moss.withValues(alpha: 0.1),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => _request(context),
              child: Text(
                idea.requestedAt == null
                    ? 'Request another time'
                    : 'Change requested time',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
