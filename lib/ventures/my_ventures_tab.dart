import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/account_screen.dart';
import 'package:lgu_one/collaboration/collab_actions.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_screen.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/esociety/idea_thread_screen.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/ventures/collab_post.dart';
import 'package:lgu_one/ventures/explore_tab.dart';

/// The student's own ventures: ideas shared with the society, upcoming
/// meetings, and team posts. Signed-out visitors are asked to sign in.
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
                  'Share it with the LGU Entrepreneurship Society for '
                  'feedback and meetings, or post a team to find students '
                  'to build it with.',
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
                  'share ideas and post teams.',
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

  void _open(Idea idea) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => IdeaThreadScreen(ideaId: idea.id)),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = EsTokens.of(context);
    return StreamBuilder<List<Idea>>(
      stream: _ideas,
      builder: (context, ideaSnap) {
        return StreamBuilder<List<CollabPost>>(
          stream: _posts,
          builder: (context, postSnap) {
            if (ideaSnap.hasError || postSnap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Your ventures could not be loaded. Check your '
                    'connection and open this page again.',
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
        );
      },
    );
  }

  Widget _content(List<Idea> ideas, List<CollabPost> posts, EsTokens t) {
    final wide = isWideWeb(context);
    final meetings = ideas.where((i) => i.hasUpcomingAppointment).toList()
      ..sort((a, b) => a.appointmentAt!.compareTo(b.appointmentAt!));
    final empty = ideas.isEmpty && posts.isEmpty;

    String count(int n, String one) => '$n $one${n == 1 ? '' : 's'}';
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your ventures', style: EsType.title(t)),
              const SizedBox(height: 4),
              Text(
                empty
                    ? 'Nothing shared yet'
                    : '${count(ideas.length, 'idea')} · '
                          '${count(posts.length, 'team')}',
                style: EsType.small(t),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: () => shareIdea(context, widget.student),
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

    final postTeam = TextButton(
      onPressed: () => CollabActions.startCreate(context),
      child: const Text('Post a team'),
    );

    final sections = <Widget>[
      if (empty) _Empty(onPostTeam: () => CollabActions.startCreate(context)),
      if (ideas.isNotEmpty)
        EsSection(
          title: 'Ideas',
          child: Column(
            children: [
              for (final idea in ideas)
                IdeaTile(
                  idea: idea,
                  unread: idea.unreadForStudent,
                  onTap: () => _open(idea),
                ),
            ],
          ),
        ),
      if (!empty) ...[
        if (ideas.isNotEmpty) const SizedBox(height: 24),
        EsSection(
          title: 'Your teams',
          trailing: postTeam,
          child: posts.isEmpty
              ? Text(
                  'Post a team to find students to build with. It goes on '
                  'the board once an admin approves it.',
                  style: EsType.body(t).copyWith(fontSize: 14, color: t.muted),
                )
              : Column(
                  children: [
                    for (final p in posts)
                      CollabPostTile(post: p, showStatus: true),
                  ],
                ),
        ),
      ],
    ];

    if (wide) {
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
                        children: sections,
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
        ...sections,
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onPostTeam;
  const _Empty({required this.onPostTeam});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share an idea and it appears here with every reply, review and '
          'meeting date from the society. Need people instead? Post a team.',
          style: EsType.body(t).copyWith(color: t.muted),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onPostTeam, child: const Text('Post a team')),
        const SizedBox(height: 24),
        Text('What happens to your idea', style: EsType.heading(t)),
        const SizedBox(height: 16),
        const StageTrack(status: IdeaStatus.accepted, captions: kStageCaptions),
      ],
    );
  }
}
