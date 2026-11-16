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

/// Student side of the Entrepreneurship Society: what it offers, a button to
/// share an idea (signed-in LGU students only), and the student's own ideas
/// with their replies and appointments.
class EsocietyScreen extends StatelessWidget {
  const EsocietyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, _) {
        final student = StudentAuthService.instance.currentStudent;
        return Scaffold(
          appBar: AppBar(title: const Text('Entrepreneurship Society')),
          floatingActionButton: student == null || isWideWeb(context)
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _share(context, student),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Share an idea'),
                ),
          body: SafeArea(
            child: isWideWeb(context)
                ? _wide(context, student)
                : _narrow(context, student),
          ),
        );
      },
    );
  }

  static Future<void> _share(BuildContext context, User student) async {
    final shared = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ShareIdeaScreen(student: student)),
    );
    if (shared == true && context.mounted) {
      await showFlushbar(
        context,
        'Idea shared. Replies will show up under My ideas.',
        color: Colors.green.shade900,
        icon: Icons.check_circle_outline,
      );
    }
  }

  Widget _narrow(BuildContext context, User? student) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _Hero(student: student, onShare: (s) => _share(context, s)),
        const SizedBox(height: 20),
        if (student == null) ...[
          const _HowItWorks(),
        ] else ...[
          _MyIdeas(student: student),
          const SizedBox(height: 24),
          const _HowItWorks(),
        ],
      ],
    );
  }

  Widget _wide(BuildContext context, User? student) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: WebConstrained(
          maxWidth: 1180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 380,
                child: Column(
                  children: [
                    _Hero(student: student, onShare: (s) => _share(context, s)),
                    const SizedBox(height: 24),
                    const _HowItWorks(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: student == null
                    ? const _SignedOutNote()
                    : _MyIdeas(student: student),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final User? student;
  final ValueChanged<User> onShare;
  const _Hero({required this.student, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onHero = Colors.white;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: webHeroDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/idea_icon.png',
                  width: 34,
                  height: 34,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'LGU Entrepreneurship Society',
                  style: TextStyle(
                    color: onHero,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Got a startup idea?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onHero,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share it with the society. They review it, reply to you here and '
            'set up meetings to help you build it.',
            style: TextStyle(
              color: onHero.withValues(alpha: 0.9),
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final s = student;
                if (s != null) {
                  onShare(s);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                }
              },
              icon: Icon(
                student == null ? Icons.login : Icons.lightbulb_outline,
              ),
              label: Text(
                student == null ? 'Sign in to share an idea' : 'Share an idea',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (student == null) ...[
            const SizedBox(height: 8),
            Text(
              'Only signed-in students with an LGU email can share ideas.',
              style: TextStyle(
                color: onHero.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const steps = [
      (
        Icons.lightbulb_outline,
        'Share',
        'Describe the problem and your solution.',
      ),
      (
        Icons.forum_outlined,
        'Get feedback',
        'The society reviews it and replies here.',
      ),
      (
        Icons.event_available,
        'Meet',
        'Confirm the appointment they set with you.',
      ),
    ];
    return EsocietyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    child: Icon(
                      steps[i].$1,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${steps[i].$2}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(steps[i].$3, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SignedOutNote extends StatelessWidget {
  const _SignedOutNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EsocietyCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Sign in to see your ideas',
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Ideas you share, the society\'s replies and your appointment dates '
            'all appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The signed-in student's ideas, with upcoming meetings pulled to the top.
class _MyIdeas extends StatefulWidget {
  final User student;
  const _MyIdeas({required this.student});

  @override
  State<_MyIdeas> createState() => _MyIdeasState();
}

class _MyIdeasState extends State<_MyIdeas> {
  late final Stream<List<Idea>> _stream = EsocietyService.instance.studentIdeas(
    widget.student.uid,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Idea>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Could not load your ideas: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final ideas = snapshot.data!;
        final meetings = ideas.where((i) => i.hasUpcomingAppointment).toList()
          ..sort((a, b) => a.appointmentAt!.compareTo(b.appointmentAt!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (meetings.isNotEmpty) ...[
              _heading(theme, Icons.event_available, 'Upcoming meetings'),
              const SizedBox(height: 10),
              for (final idea in meetings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _open(idea),
                    child: AppointmentCard(idea: idea),
                  ),
                ),
              const SizedBox(height: 14),
            ],
            _heading(
              theme,
              Icons.lightbulb_outline,
              'My ideas (${ideas.length})',
            ),
            const SizedBox(height: 10),
            if (ideas.isEmpty)
              EsocietyCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No ideas yet',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ideas you share will appear here with every reply.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              for (final idea in ideas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IdeaTile(
                    idea: idea,
                    unread: idea.unreadForStudent,
                    onTap: () => _open(idea),
                  ),
                ),
          ],
        );
      },
    );
  }

  void _open(Idea idea) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IdeaThreadScreen(ideaId: idea.id)),
    );
  }

  Widget _heading(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}

/// One idea in a list. [showStudent] adds who shared it (portal view).
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
    final theme = Theme.of(context);
    final fromSociety = idea.lastMessageBy == 'society';
    return EsocietyCard(
      highlighted: unread,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showStudent) ...[
                PersonAvatar(
                  name: idea.studentName,
                  photoUrl: idea.studentPhoto,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (showStudent) idea.studentName,
                        if (showStudent && idea.studentLine.isNotEmpty)
                          idea.studentLine,
                        if (!showStudent) idea.category,
                        if (!showStudent) idea.stage,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IdeaStatusChip(idea.status, dense: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                fromSociety ? Icons.forum : Icons.forum_outlined,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  idea.lastMessagePreview.isEmpty
                      ? 'No replies yet'
                      : '${fromSociety ? 'E-Society' : (showStudent ? 'Student' : 'You')}: '
                            '${idea.lastMessagePreview}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                relativeTime(idea.lastActivityAt),
                style: theme.textTheme.bodySmall,
              ),
              if (unread) ...[const SizedBox(width: 8), const UnreadDot()],
            ],
          ),
          if (idea.hasUpcomingAppointment) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${kAppointmentFormat.format(idea.appointmentAt!)} · '
                    '${(idea.appointmentState ?? AppointmentState.proposed).label}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (idea.reviewRating != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                StarRow(idea.reviewRating!, size: 15),
                const SizedBox(width: 6),
                Text('Society review', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
