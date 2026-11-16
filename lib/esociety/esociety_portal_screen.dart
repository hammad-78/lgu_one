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

/// Home of the Entrepreneurship Society portal: the ideas inbox, every
/// appointment, and student collaborations to contact and review.
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
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: Text(
                      widget.member.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                // Admins reach the portal from the admin console; signing out
                // here would also end their admin session.
                if (widget.member.role != 'Admin')
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout),
                    onPressed: _signOut,
                  ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(child: _tabLabel('Ideas', unread)),
                  Tab(child: _tabLabel('Appointments', upcoming)),
                  const Tab(text: 'Collaborations'),
                ],
              ),
            ),
            body: snapshot.hasError
                ? Center(child: Text('Could not load ideas: ${snapshot.error}'))
                : TabBarView(
                    children: [
                      _IdeasTab(
                        ideas: ideas,
                        loading: !snapshot.hasData,
                        member: widget.member,
                      ),
                      _AppointmentsTab(ideas: ideas, member: widget.member),
                      _CollaborationsTab(member: widget.member),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _tabLabel(String text, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ],
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
  /// null = all open ideas; 'unread' = needs a reply.
  String? _filter;
  final _search = TextEditingController();

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

  bool _matches(Idea i) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty &&
        !('${i.title} ${i.studentName} ${i.category} ${i.studentEmail}')
            .toLowerCase()
            .contains(q)) {
      return false;
    }
    return switch (_filter) {
      null => i.status != IdeaStatus.withdrawn,
      'unread' => i.unreadForSociety,
      final s => i.status.value == s,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final ideas = widget.ideas;
    int count(IdeaStatus s) => ideas.where((i) => i.status == s).length;
    final unread = ideas.where((i) => i.unreadForSociety).length;
    final shown = ideas.where(_matches).toList();
    final wide = isWideWeb(context);

    final stats = [
      _Stat('Need reply', unread, Icons.mark_chat_unread_outlined, () {
        setState(() => _filter = 'unread');
      }),
      _Stat('New', count(IdeaStatus.submitted), IdeaStatus.submitted.icon, () {
        setState(() => _filter = IdeaStatus.submitted.value);
      }),
      _Stat(
        'In review',
        count(IdeaStatus.underReview),
        IdeaStatus.underReview.icon,
        () => setState(() => _filter = IdeaStatus.underReview.value),
      ),
      _Stat(
        'Shortlisted',
        count(IdeaStatus.shortlisted),
        IdeaStatus.shortlisted.icon,
        () => setState(() => _filter = IdeaStatus.shortlisted.value),
      ),
      _Stat(
        'Accepted',
        count(IdeaStatus.accepted),
        IdeaStatus.accepted.icon,
        () => setState(() => _filter = IdeaStatus.accepted.value),
      ),
    ];

    final filters = <(String?, String)>[
      (null, 'All open'),
      ('unread', 'Needs reply'),
      for (final s in IdeaStatus.values) (s.value, s.label),
    ];

    return adminCentered(
      context,
      maxWidth: 980,
      ListView(
        padding: EdgeInsets.all(wide ? 28 : 16),
        children: [
          // Cards size to their content, so larger text never overflows.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _StatCard(stat: stats[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search by idea, student or category',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: _search.clear,
                    ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) => setState(() => _filter = f.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ideas.isEmpty
                        ? 'No ideas shared yet'
                        : 'No ideas match this filter',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            for (final idea in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IdeaTile(
                  idea: idea,
                  unread: idea.unreadForSociety,
                  showStudent: true,
                  onTap: () => _openIdea(context, idea, widget.member),
                ),
              ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onTap;
  const _Stat(this.label, this.value, this.icon, this.onTap);
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 140,
      child: EsocietyCard(
        onTap: stat.onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(stat.icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${stat.value}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Appointments ───────────────────────────────────────────────────────────

class _AppointmentsTab extends StatelessWidget {
  final List<Idea> ideas;
  final EsocietyMember member;
  const _AppointmentsTab({required this.ideas, required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withDate = ideas.where((i) => i.appointmentAt != null).toList();
    final upcoming = withDate.where((i) => i.hasUpcomingAppointment).toList()
      ..sort((a, b) => a.appointmentAt!.compareTo(b.appointmentAt!));
    final past = withDate.where((i) => !i.hasUpcomingAppointment).toList()
      ..sort((a, b) => b.appointmentAt!.compareTo(a.appointmentAt!));

    if (withDate.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              const Text('No appointments yet'),
              const SizedBox(height: 4),
              Text(
                'Open an idea and choose Appointment to set one.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    Widget entry(Idea idea) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openIdea(context, idea, member),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                '${idea.studentName} · ${idea.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            AppointmentCard(idea: idea),
          ],
        ),
      ),
    );

    return adminCentered(
      context,
      maxWidth: 760,
      ListView(
        padding: EdgeInsets.all(isWideWeb(context) ? 28 : 16),
        children: [
          if (upcoming.isNotEmpty) ...[
            _heading(theme, 'Upcoming (${upcoming.length})'),
            ...upcoming.map(entry),
            const SizedBox(height: 12),
          ],
          if (past.isNotEmpty) ...[
            _heading(theme, 'Past and cancelled'),
            ...past.map(entry),
          ],
        ],
      ),
    );
  }

  Widget _heading(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: theme.textTheme.headlineMedium?.copyWith(fontSize: 17),
    ),
  );
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
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!;
        if (docs.isEmpty) {
          return const Center(child: Text('No approved collaborations yet'));
        }
        return adminCentered(
          context,
          maxWidth: 820,
          ListView.builder(
            padding: EdgeInsets.all(isWideWeb(context) ? 28 : 16),
            itemCount: docs.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CollabCard(doc: docs[i], member: widget.member),
            ),
          ),
        );
      },
    );
  }
}

class _CollabCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final EsocietyMember member;
  const _CollabCard({required this.doc, required this.member});

  Future<void> _review(BuildContext context, CollabReview? mine) async {
    final result = await showReviewDialog(
      context,
      title: mine == null ? 'Review collaboration' : 'Edit your review',
      initialRating: mine?.rating ?? 0,
      initialText: mine?.comment ?? '',
    );
    if (result == null || !context.mounted) return;
    try {
      await EsocietyService.instance.saveCollabReview(
        doc.id,
        member,
        rating: result.$1,
        comment: result.$2,
      );
      if (context.mounted) {
        showFlushbar(context, 'Review saved', color: Colors.green.shade900);
      }
    } catch (e) {
      if (context.mounted) {
        showFlushbar(
          context,
          'Could not save review: $e',
          color: Colors.red.shade900,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = (doc.data()['info'] as Map?)?.cast<String, dynamic>() ?? {};
    final posts = ((info['requiredPosts'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final phone = (info['whatsappNumber'] ?? '').toString();
    final title = (info['title'] ?? '').toString();

    return EsocietyCard(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<CollabReview>>(
        stream: EsocietyService.instance.collabReviews(doc.id),
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? const <CollabReview>[];
          CollabReview? mine;
          for (final r in reviews) {
            if (r.reviewerUid == member.uid) mine = r;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text((info['category'] ?? '').toString()),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if ((info['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  info['description'].toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.5),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Members ${info['existingMembers'] ?? 0}/'
                    '${info['requiredMembers'] ?? 0}',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
              if (posts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: posts
                      .map(
                        (p) => Chip(
                          label: Text(p, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (reviews.isNotEmpty) ...[
                const Divider(height: 24),
                CollabReviewList(reviews: reviews),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (phone.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => openWhatsApp(
                        phone,
                        'Hi, this is ${member.name} from the LGU '
                        'Entrepreneurship Society about your collaboration '
                        '"$title".',
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('Contact'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _review(context, mine),
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text(mine == null ? 'Review' : 'Edit review'),
                  ),
                  if (mine != null)
                    TextButton.icon(
                      onPressed: () => EsocietyService.instance
                          .deleteCollabReview(doc.id, member),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove review'),
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
