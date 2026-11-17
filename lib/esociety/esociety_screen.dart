import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/esociety/share_idea_screen.dart';
import 'package:lgu_one/utils/flushbar.dart';

/// What each stage means to a student, shown under the stage track.
const List<String> kStageCaptions = [
  'You describe the problem and your solution.',
  'The society reads it and replies here.',
  'They meet you to dig into it.',
  'They back it with mentoring and support.',
];

/// Opens the venture form for [student] and confirms once it is sent.
/// [forSociety] and [findTeam] preselect what they need.
Future<void> shareIdea(
  BuildContext context,
  User student, {
  bool forSociety = true,
  bool findTeam = false,
}) async {
  final message = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => ShareIdeaScreen(
        student: student,
        forSociety: forSociety,
        findTeam: findTeam,
      ),
    ),
  );
  if (message != null && context.mounted) {
    await showFlushbar(
      context,
      message,
      color: Colors.green.shade900,
      icon: Icons.check_circle_outline,
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

  /// How the idea's team stands (portal), shown under the stage line.
  final String? teamLine;
  const IdeaTile({
    super.key,
    required this.idea,
    required this.unread,
    required this.onTap,
    this.showStudent = false,
    this.teamLine,
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
          if (teamLine != null) ...[
            const SizedBox(height: 2),
            Text(
              teamLine!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EsType.small(t),
            ),
          ],
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
