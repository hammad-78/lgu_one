import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/esociety/meeting_time_dialog.dart';
import 'package:lgu_one/notification/notification_service.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/whatsApp_support.dart';
import 'package:url_launcher/url_launcher.dart';

/// Width from which ideas are laid out as a grid instead of a swiper.
const double _kGridBreakpoint = 720;

/// The Entrepreneurship Society portal: ideas students sent, as Active and
/// Past. The society sends meeting times, approves a student's request for
/// another time, and deactivates ideas.
class EsocietyPortalScreen extends StatefulWidget {
  final EsocietyMember member;
  const EsocietyPortalScreen({super.key, required this.member});

  @override
  State<EsocietyPortalScreen> createState() => _EsocietyPortalScreenState();
}

class _EsocietyPortalScreenState extends State<EsocietyPortalScreen> {
  late final Stream<List<Idea>> _ideas = EsocietyService.instance.allIdeas();

  @override
  void initState() {
    super.initState();
    // So new ideas and time requests reach this member's phone.
    NotificationService.linkTokenToUser(widget.member.uid);
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await NotificationService.linkTokenToUser(null);
    await FirebaseAuth.instance.signOut();
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: StreamBuilder<List<Idea>>(
        stream: _ideas,
        builder: (context, snapshot) {
          final ideas = snapshot.data ?? const <Idea>[];
          final active = ideas.where((i) => !i.isPast).toList();
          final past = ideas.where((i) => i.isPast).toList();

          Widget tab(List<Idea> list, String empty) => !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : _IdeaDeck(ideas: list, all: ideas, emptyText: empty);

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
                  Tab(text: 'Active (${active.length})'),
                  Tab(text: 'Past (${past.length})'),
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
                      tab(active, 'No active ideas. New ones show up here.'),
                      tab(
                        past,
                        'Ideas move here once their meeting has happened or '
                        'you deactivate them.',
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ─── Layout ─────────────────────────────────────────────────────────────────

/// [ideas] as a swiper on phones and a grid on wide screens. [all] is every
/// idea, used to keep meeting times from clashing.
class _IdeaDeck extends StatefulWidget {
  final List<Idea> ideas;
  final List<Idea> all;
  final String emptyText;
  const _IdeaDeck({
    required this.ideas,
    required this.all,
    required this.emptyText,
  });

  @override
  State<_IdeaDeck> createState() => _IdeaDeckState();
}

class _IdeaDeckState extends State<_IdeaDeck>
    with AutomaticKeepAliveClientMixin {
  int _index = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = EsTokens.of(context);
    final ideas = widget.ideas;
    if (ideas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            widget.emptyText,
            textAlign: TextAlign.center,
            style: EsType.body(t).copyWith(color: t.muted),
          ),
        ),
      );
    }

    if (MediaQuery.sizeOf(context).width >= _kGridBreakpoint) {
      return GridView.extent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 470,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        padding: const EdgeInsets.all(24),
        children: [
          for (final idea in ideas) _IdeaCard(idea: idea, all: widget.all),
        ],
      );
    }

    final index = _index.clamp(0, ideas.length - 1);
    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            // A new deck when ideas come or go, so the index stays valid.
            key: ValueKey(ideas.map((i) => i.id).join(',')),
            cardsCount: ideas.length,
            initialIndex: index,
            numberOfCardsDisplayed: ideas.length < 3 ? ideas.length : 3,
            backCardOffset: const Offset(0, 28),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
              horizontal: true,
            ),
            onSwipe: (_, current, _) {
              setState(() => _index = current ?? 0);
              return true;
            },
            cardBuilder: (context, i, _, _) =>
                _IdeaCard(idea: ideas[i], all: widget.all),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${index + 1} of ${ideas.length} · swipe for the next idea',
            style: EsType.small(t),
          ),
        ),
      ],
    );
  }
}

// ─── Card ───────────────────────────────────────────────────────────────────

/// One idea: who sent it, a short look at it, its meeting and the
/// society's actions. The info button opens it in full.
class _IdeaCard extends StatelessWidget {
  final Idea idea;
  final List<Idea> all;
  const _IdeaCard({required this.idea, required this.all});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? t.surface : Colors.white,
      elevation: dark ? 0 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: t.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      idea.category,
                      relativeTime(idea.createdAt),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: EsType.small(t),
                  ),
                ),
                IconButton(
                  tooltip: 'View full idea',
                  icon: Icon(Icons.info_outline, color: t.moss),
                  onPressed: () => _openDetail(context, idea, all),
                ),
              ],
            ),
            // Scrolls on short screens instead of overflowing; swiping
            // stays horizontal so the two don't fight.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: EsType.title(t).copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    _StudentRow(idea: idea),
                    const SizedBox(height: 12),
                    Text(
                      idea.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: EsType.body(t).copyWith(color: t.muted),
                    ),
                    const SizedBox(height: 16),
                    _MeetingPanel(idea: idea, all: all),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final Idea idea;
  const _StudentRow({required this.idea});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Row(
      children: [
        PersonAvatar(
          name: idea.studentName,
          photoUrl: idea.studentPhoto,
          radius: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                idea.studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: EsType.body(
                  t,
                ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (idea.studentLine.isNotEmpty)
                Text(
                  idea.studentLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EsType.small(t).copyWith(fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Meeting ────────────────────────────────────────────────────────────────

/// The meeting time, the student's request if any, and the actions.
class _MeetingPanel extends StatelessWidget {
  final Idea idea;
  final List<Idea> all;
  const _MeetingPanel({required this.idea, required this.all});

  String? _clash(DateTime at) {
    final other = meetingClash(all, at, except: idea.id);
    return other == null
        ? null
        : 'Clashes with "${other.title}" at '
              '${kTimeFormat.format(other.meetingAt!)}. Pick another time.';
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        await showFlushbar(
          context,
          'Could not save. Check your connection and try again.',
          color: Colors.red.shade900,
        );
      }
    }
  }

  Future<void> _sendTime(BuildContext context) async {
    final picked = await showMeetingTimeDialog(
      context,
      title: idea.meetingAt == null ? 'Send a meeting time' : 'Change the time',
      textLabel: 'Place (optional)',
      confirmLabel: 'Send',
      initial: idea.meetingAt,
      initialText: idea.meetingPlace,
      clash: _clash,
    );
    if (picked == null || !context.mounted) return;
    await _run(
      context,
      () => EsocietyService.instance.setMeeting(idea, picked.$1, picked.$2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final meeting = idea.meetingAt;
    final requested = idea.requestedAt;
    final requestProblem = requested == null
        ? null
        : requested.isBefore(DateTime.now())
        ? 'This time has passed.'
        : _clash(requested);

    final sendLabel = meeting == null || idea.meetingPassed
        ? 'Send time'
        : requested != null
        ? 'Other time'
        : 'Change time';
    final small = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.moss.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 18, color: t.moss),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting == null
                          ? 'No meeting time sent yet'
                          : [
                              kMeetingFormat.format(meeting),
                              if (idea.meetingPlace.isNotEmpty)
                                idea.meetingPlace,
                            ].join(' · '),
                      style: EsType.body(t).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: meeting == null ? t.muted : t.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (requested != null && !idea.deactivated) ...[
                const SizedBox(height: 8),
                Text(
                  'Student asked for ${kMeetingFormat.format(requested)}'
                  '${idea.requestNote.isEmpty ? '' : '\n"${idea.requestNote}"'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: EsType.small(t).copyWith(color: t.ink),
                ),
                if (requestProblem != null)
                  Text(
                    requestProblem,
                    style: EsType.small(t).copyWith(color: t.clay),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: idea.deactivated
              ? [
                  OutlinedButton(
                    style: small,
                    onPressed: () => _run(
                      context,
                      () =>
                          EsocietyService.instance.setDeactivated(idea, false),
                    ),
                    child: const Text('Reactivate'),
                  ),
                ]
              : [
                  if (requested != null)
                    FilledButton(
                      style: small,
                      onPressed: requestProblem != null
                          ? null
                          : () => _run(
                              context,
                              () =>
                                  EsocietyService.instance.approveRequest(idea),
                            ),
                      child: const Text('Approve time'),
                    ),
                  if (requested == null)
                    FilledButton(
                      style: small,
                      onPressed: () => _sendTime(context),
                      child: Text(sendLabel),
                    )
                  else
                    OutlinedButton(
                      style: small,
                      onPressed: () => _sendTime(context),
                      child: Text(sendLabel),
                    ),
                  TextButton(
                    style: small.copyWith(
                      foregroundColor: WidgetStatePropertyAll(t.clay),
                    ),
                    onPressed: () => _run(
                      context,
                      () => EsocietyService.instance.setDeactivated(idea, true),
                    ),
                    child: const Text('Deactivate'),
                  ),
                ],
        ),
      ],
    );
  }
}

// ─── Detail ─────────────────────────────────────────────────────────────────

void _openDetail(BuildContext context, Idea idea, List<Idea> all) {
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _IdeaDetailScreen(ideaId: idea.id, all: all),
    ),
  );
}

/// The whole idea on one screen, kept live so actions taken here show.
class _IdeaDetailScreen extends StatefulWidget {
  final String ideaId;
  final List<Idea> all;
  const _IdeaDetailScreen({required this.ideaId, required this.all});

  @override
  State<_IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<_IdeaDetailScreen> {
  late final Stream<List<Idea>> _ideas = EsocietyService.instance.allIdeas();

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Idea')),
      body: SafeArea(
        child: StreamBuilder<List<Idea>>(
          stream: _ideas,
          initialData: widget.all,
          builder: (context, snapshot) {
            final ideas = snapshot.data ?? widget.all;
            final idea = ideas.where((i) => i.id == widget.ideaId).firstOrNull;
            if (idea == null) {
              return Center(
                child: Text('This idea was removed.', style: EsType.body(t)),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: _detail(idea, ideas, t),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _detail(Idea idea, List<Idea> ideas, EsTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(idea.title, style: EsType.title(t).copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Text(
          'Sent ${relativeTime(idea.createdAt)}'
          '${idea.deactivated ? ' · Deactivated' : ''}',
          style: EsType.small(t),
        ),
        const SizedBox(height: 16),
        _StudentRow(idea: idea),
        const SizedBox(height: 20),
        Text(idea.description, style: EsType.body(t)),
        const SizedBox(height: 20),
        FactList([
          ('Category', idea.category),
          ('Team', idea.teamLine),
          ('Looking for', idea.roles.join(', ')),
          ('Email', idea.studentEmail),
          ('WhatsApp', idea.whatsapp),
        ]),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (idea.whatsapp.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => openWhatsApp(
                  idea.whatsapp,
                  'Hi ${idea.studentName.split(' ').first}, this is the LGU '
                  'Entrepreneurship Society about "${idea.title}".',
                ),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('WhatsApp'),
              ),
            if (idea.studentEmail.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri(
                    scheme: 'mailto',
                    path: idea.studentEmail,
                    queryParameters: {'subject': idea.title},
                  ),
                ),
                icon: const Icon(Icons.mail_outline, size: 18),
                label: const Text('Email'),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Meeting', style: EsType.heading(t)),
        const SizedBox(height: 10),
        _MeetingPanel(idea: idea, all: ideas),
      ],
    );
  }
}
