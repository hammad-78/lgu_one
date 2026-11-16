import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/collab_reviews.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_screen.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/esociety/idea_thread_screen.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/utils/whatsApp_support.dart';

/// Home of the Entrepreneurship Society portal: ideas by stage, the meeting
/// agenda, and student collaborations to contact and review.
class EsocietyPortalScreen extends StatefulWidget {
  final EsocietyMember member;
  const EsocietyPortalScreen({super.key, required this.member});

  @override
  State<EsocietyPortalScreen> createState() => _EsocietyPortalScreenState();
}

class _EsocietyPortalScreenState extends State<EsocietyPortalScreen> {
  late final Stream<List<Idea>> _ideas = EsocietyService.instance.allIdeas();

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: StreamBuilder<List<Idea>>(
        stream: _ideas,
        builder: (context, snapshot) {
          final ideas = snapshot.data ?? const <Idea>[];
          final unread = ideas.where((i) => i.unreadForSociety).length;
          final upcoming = ideas.where((i) => i.hasUpcomingAppointment).length;

          return Scaffold(
            appBar: AppBar(
              title: const Text('E-Society Portal'),
              actions: [
                // Admins arrive from the admin console; signing out here
                // would also end their admin session.
                if (widget.member.role != 'Admin')
                  IconButton(
                    tooltip: 'Sign out ${widget.member.name}',
                    icon: const Icon(Icons.logout),
                    onPressed: _signOut,
                  ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: unread > 0 ? 'Ideas ($unread new)' : 'Ideas'),
                  Tab(text: upcoming > 0 ? 'Meetings ($upcoming)' : 'Meetings'),
                  const Tab(text: 'Collaborations'),
                ],
              ),
            ),
            body: snapshot.hasError
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ideas could not be loaded. Check that this account '
                        'is a society member and try again.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : TabBarView(
                    children: [
                      _IdeasTab(
                        ideas: ideas,
                        loading: !snapshot.hasData,
                        member: widget.member,
                      ),
                      _MeetingsTab(ideas: ideas, member: widget.member),
                      _CollaborationsTab(member: widget.member),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

void _openIdea(BuildContext context, Idea idea, EsocietyMember member) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => IdeaThreadScreen(ideaId: idea.id, member: member),
    ),
  );
}

// ─── Ideas ──────────────────────────────────────────────────────────────────

/// Filters for the phone list. `open` hides closed ideas.
enum _Filter {
  open,
  unread,
  submitted,
  underReview,
  shortlisted,
  accepted,
  closed,
}

class _IdeasTab extends StatefulWidget {
  final List<Idea> ideas;
  final bool loading;
  final EsocietyMember member;
  const _IdeasTab({
    required this.ideas,
    required this.loading,
    required this.member,
  });

  @override
  State<_IdeasTab> createState() => _IdeasTabState();
}

class _IdeasTabState extends State<_IdeasTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  _Filter _filter = _Filter.open;
  bool _onlyUnread = false;
  bool _showClosed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesSearch(Idea i) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return '${i.title} ${i.studentName} ${i.category} ${i.studentEmail}'
        .toLowerCase()
        .contains(q);
  }

  bool _matchesFilter(Idea i, _Filter f) => switch (f) {
    _Filter.open => !i.status.isClosed,
    _Filter.unread => i.unreadForSociety,
    _Filter.submitted => i.status == IdeaStatus.submitted,
    _Filter.underReview => i.status == IdeaStatus.underReview,
    _Filter.shortlisted => i.status == IdeaStatus.shortlisted,
    _Filter.accepted => i.status == IdeaStatus.accepted,
    _Filter.closed => i.status.isClosed,
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = EsTokens.of(context);
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final searched = widget.ideas.where(_matchesSearch).toList();

    final search = TextField(
      controller: _search,
      decoration: InputDecoration(
        hintText: 'Search ideas, students or categories',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: _search.clear,
              ),
        isDense: true,
        filled: true,
        fillColor: t.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );

    if (widget.ideas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No ideas yet', style: EsType.title(t)),
                const SizedBox(height: 8),
                Text(
                  'When students share an idea from the app it lands here, '
                  'in the Submitted column.',
                  style: EsType.body(t).copyWith(color: t.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isWideWeb(context)) return _board(searched, search);
    return _list(searched, search);
  }

  /// Wide screens: one column per stage, like a pipeline board.
  Widget _board(List<Idea> ideas, Widget search) {
    final shown = _onlyUnread
        ? ideas.where((i) => i.unreadForSociety).toList()
        : ideas;
    final columns = <(String, List<Idea>)>[
      for (final s in IdeaStatus.track)
        (s.label, shown.where((i) => i.status == s).toList()),
      if (_showClosed)
        ('Closed', shown.where((i) => i.status.isClosed).toList()),
    ];
    final unread = ideas.where((i) => i.unreadForSociety).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 380, child: search),
              const SizedBox(width: 12),
              FilterChip(
                label: Text('Needs a reply ($unread)'),
                selected: _onlyUnread,
                onSelected: (v) => setState(() => _onlyUnread = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Show closed'),
                selected: _showClosed,
                onSelected: (v) => setState(() => _showClosed = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns.length; i++) ...[
                  if (i > 0) const SizedBox(width: 28),
                  Expanded(
                    child: _BoardColumn(
                      title: columns[i].$1,
                      ideas: columns[i].$2,
                      member: widget.member,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Phones: one list, with stage filters that show their counts.
  Widget _list(List<Idea> ideas, Widget search) {
    final t = EsTokens.of(context);
    int count(_Filter f) => ideas.where((i) => _matchesFilter(i, f)).length;
    final filters = <(_Filter, String)>[
      (_Filter.open, 'All open'),
      (_Filter.unread, 'Needs a reply'),
      (_Filter.submitted, 'Submitted'),
      (_Filter.underReview, 'In review'),
      (_Filter.shortlisted, 'Shortlisted'),
      (_Filter.accepted, 'Accepted'),
      (_Filter.closed, 'Closed'),
    ];
    final shown = ideas.where((i) => _matchesFilter(i, _filter)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        search,
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${f.$2} (${count(f.$1)})'),
                    selected: _filter == f.$1,
                    onSelected: (_) => setState(() => _filter = f.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              _filter == _Filter.unread
                  ? 'You are up to date. No idea is waiting for a reply.'
                  : 'No ideas here. Try another filter or clear the search.',
              textAlign: TextAlign.center,
              style: EsType.body(t).copyWith(color: t.muted),
            ),
          )
        else
          for (final idea in shown)
            IdeaTile(
              idea: idea,
              unread: idea.unreadForSociety,
              showStudent: true,
              onTap: () => _openIdea(context, idea, widget.member),
            ),
      ],
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final String title;
  final List<Idea> ideas;
  final EsocietyMember member;
  const _BoardColumn({
    required this.title,
    required this.ideas,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: EsType.heading(t)),
            const SizedBox(width: 8),
            Text('${ideas.length}', style: EsType.small(t)),
          ],
        ),
        const SizedBox(height: 4),
        Divider(height: 1, color: t.ink.withValues(alpha: 0.5)),
        Expanded(
          child: ideas.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text('Nothing here', style: EsType.small(t)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 24),
                  itemCount: ideas.length,
                  itemBuilder: (context, i) =>
                      _BoardCard(idea: ideas[i], member: member),
                ),
        ),
      ],
    );
  }
}

class _BoardCard extends StatelessWidget {
  final Idea idea;
  final EsocietyMember member;
  const _BoardCard({required this.idea, required this.member});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final unread = idea.unreadForSociety;
    final line = idea.status.isClosed
        ? idea.status.label
        : idea.hasUpcomingAppointment
        ? 'Meeting ${kShortDateFormat.format(idea.appointmentAt!)}'
        : unread
        ? 'Student wrote ${relativeTime(idea.lastActivityAt).toLowerCase()}'
        : 'Updated ${relativeTime(idea.lastActivityAt).toLowerCase()}';
    return EsPanel(
      padding: const EdgeInsets.all(12),
      onTap: () => _openIdea(context, idea, member),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: EsType.heading(t).copyWith(
                    fontSize: 14.5,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  idea.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EsType.small(t).copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  style: EsType.small(t).copyWith(
                    fontSize: 12,
                    color: idea.status.isClosed
                        ? t.statusColor(idea.status)
                        : unread
                        ? t.moss
                        : t.muted,
                  ),
                ),
              ],
            ),
          ),
          if (unread) ...[
            const SizedBox(width: 8),
            const Padding(padding: EdgeInsets.only(top: 6), child: UnreadDot()),
          ],
        ],
      ),
    );
  }
}

// ─── Meetings ───────────────────────────────────────────────────────────────

/// Meetings as an agenda: grouped by day, time on the left.
class _MeetingsTab extends StatelessWidget {
  final List<Idea> ideas;
  final EsocietyMember member;
  const _MeetingsTab({required this.ideas, required this.member});

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return kDayFormat.format(d);
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final withDate = ideas.where((i) => i.appointmentAt != null).toList();
    final upcoming = withDate.where((i) => i.hasUpcomingAppointment).toList()
      ..sort((a, b) => a.appointmentAt!.compareTo(b.appointmentAt!));
    final earlier = withDate.where((i) => !i.hasUpcomingAppointment).toList()
      ..sort((a, b) => b.appointmentAt!.compareTo(a.appointmentAt!));

    if (withDate.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No meetings scheduled', style: EsType.title(t)),
                const SizedBox(height: 8),
                Text(
                  'Open an idea and choose Schedule meeting. The student is '
                  'asked to confirm, and the meeting shows up here.',
                  style: EsType.body(t).copyWith(color: t.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Widget> agenda(List<Idea> list, {required bool faded}) {
      final out = <Widget>[];
      String? lastDay;
      for (final idea in list) {
        final day = _dayLabel(idea.appointmentAt!);
        if (day != lastDay) {
          out.add(
            Padding(
              padding: EdgeInsets.only(
                top: lastDay == null ? 0 : 20,
                bottom: 8,
              ),
              child: Text(
                day,
                style: EsType.heading(
                  t,
                ).copyWith(color: faded ? t.muted : t.ink),
              ),
            ),
          );
          lastDay = day;
        }
        out.add(_AgendaRow(idea: idea, member: member, faded: faded));
      }
      return out;
    }

    return adminCentered(
      context,
      maxWidth: 720,
      ListView(
        padding: EdgeInsets.all(isWideWeb(context) ? 32 : 16),
        children: [
          if (upcoming.isEmpty)
            Text(
              'Nothing coming up.',
              style: EsType.body(t).copyWith(color: t.muted),
            )
          else
            ...agenda(upcoming, faded: false),
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: 36),
            Text('Earlier and cancelled', style: EsType.small(t)),
            Divider(color: t.rule),
            const SizedBox(height: 8),
            ...agenda(earlier, faded: true),
          ],
        ],
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  final Idea idea;
  final EsocietyMember member;
  final bool faded;
  const _AgendaRow({
    required this.idea,
    required this.member,
    required this.faded,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final state = idea.appointmentState ?? AppointmentState.proposed;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openIdea(context, idea, member),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Text(
                kTimeFormat.format(idea.appointmentAt!),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: faded ? t.muted : t.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea.studentName,
                    style: EsType.body(t).copyWith(
                      fontWeight: FontWeight.w700,
                      color: faded ? t.muted : t.ink,
                    ),
                  ),
                  Text(
                    idea.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EsType.small(t),
                  ),
                  if (idea.appointmentPlace.isNotEmpty)
                    Text(idea.appointmentPlace, style: EsType.small(t)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              faded && state != AppointmentState.cancelled
                  ? 'Took place'
                  : state.label(forSociety: true),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: faded && state != AppointmentState.cancelled
                    ? t.muted
                    : t.appointmentColor(state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Collaborations ─────────────────────────────────────────────────────────

class _CollaborationsTab extends StatefulWidget {
  final EsocietyMember member;
  const _CollaborationsTab({required this.member});

  @override
  State<_CollaborationsTab> createState() => _CollaborationsTabState();
}

class _CollaborationsTabState extends State<_CollaborationsTab>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _stream =
      EsocietyService.instance.collaborations();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = EsTokens.of(context);
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Collaborations could not be loaded. Try again.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!;
        return adminCentered(
          context,
          maxWidth: 760,
          ListView(
            padding: EdgeInsets.all(isWideWeb(context) ? 32 : 16),
            children: [
              Text(
                'Student projects that are open for members. Contact the team '
                'or leave feedback; students see your review on the project.',
                style: EsType.body(t).copyWith(color: t.muted),
              ),
              const SizedBox(height: 20),
              if (docs.isEmpty)
                Text('No approved collaborations yet.', style: EsType.body(t)),
              for (final doc in docs)
                _CollabCard(
                  key: ValueKey(doc.id),
                  doc: doc,
                  member: widget.member,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CollabCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final EsocietyMember member;
  const _CollabCard({super.key, required this.doc, required this.member});

  @override
  State<_CollabCard> createState() => _CollabCardState();
}

class _CollabCardState extends State<_CollabCard> {
  late final Stream<List<CollabReview>> _reviews = EsocietyService.instance
      .collabReviews(widget.doc.id);

  Future<void> _review(CollabReview? mine) async {
    final result = await showReviewDialog(
      context,
      title: mine == null ? 'Review this project' : 'Edit your review',
      initialRating: mine?.rating ?? 0,
      initialText: mine?.comment ?? '',
    );
    if (result == null || !mounted) return;
    try {
      await EsocietyService.instance.saveCollabReview(
        widget.doc.id,
        widget.member,
        rating: result.$1,
        comment: result.$2,
      );
      if (mounted) {
        showFlushbar(context, 'Review saved', color: Colors.green.shade900);
      }
    } catch (e) {
      if (mounted) {
        showFlushbar(
          context,
          'Review not saved. Try again.',
          color: Colors.red.shade900,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final info =
        (widget.doc.data()['info'] as Map?)?.cast<String, dynamic>() ?? {};
    final posts = ((info['requiredPosts'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final phone = (info['whatsappNumber'] ?? '').toString();
    final title = (info['title'] ?? '').toString();
    final category = (info['category'] ?? '').toString();
    final description = (info['description'] ?? '').toString();
    final members =
        '${info['existingMembers'] ?? 0} of ${info['requiredMembers'] ?? 0} '
        'members';

    return EsPanel(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<CollabReview>>(
        stream: _reviews,
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? const <CollabReview>[];
          CollabReview? mine;
          for (final r in reviews) {
            if (r.reviewerUid == widget.member.uid) mine = r;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: EsType.heading(t).copyWith(fontSize: 17)),
              const SizedBox(height: 2),
              Text(
                category.isEmpty ? members : '$category, $members',
                style: EsType.small(t),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(description, style: EsType.body(t).copyWith(fontSize: 14)),
              ],
              if (posts.isNotEmpty) ...[
                const SizedBox(height: 10),
                FactList([('Looking for', posts.join(', '))]),
              ],
              if (reviews.isNotEmpty) ...[
                Divider(height: 28, color: t.rule),
                CollabReviewList(reviews: reviews),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (phone.isNotEmpty)
                    TextButton(
                      onPressed: () => openWhatsApp(
                        phone,
                        'Hi, this is ${widget.member.name} from the LGU '
                        'Entrepreneurship Society, about your project '
                        '"$title".',
                      ),
                      child: const Text('Message on WhatsApp'),
                    ),
                  TextButton(
                    onPressed: () => _review(mine),
                    child: Text(mine == null ? 'Write review' : 'Edit review'),
                  ),
                  if (mine != null)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: t.clay),
                      onPressed: () => EsocietyService.instance
                          .deleteCollabReview(widget.doc.id, widget.member),
                      child: const Text('Remove review'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
