import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/ventures/collab_post.dart';
import 'package:lgu_one/ventures/collab_post_screen.dart';
import 'package:lgu_one/ventures/team_post_screen.dart';
import 'package:lgu_one/ventures/ventures_service.dart';

/// The team side of an idea, inside its thread. The student can find
/// teammates for it, stop or resume recruiting and open the post; the
/// society sees how the team stands.
class IdeaTeamPanel extends StatefulWidget {
  final Idea idea;

  /// The signed-in student who owns the idea, or null for the society.
  final User? owner;
  const IdeaTeamPanel({super.key, required this.idea, this.owner});

  @override
  State<IdeaTeamPanel> createState() => _IdeaTeamPanelState();
}

class _IdeaTeamPanelState extends State<IdeaTeamPanel> {
  String? _streamId;
  Stream<CollabPost?>? _stream;
  bool _busy = false;

  /// Post ids whose badge this panel already corrected.
  final Set<String> _synced = {};

  /// When the society looks at an idea, fixes a team badge that is missing
  /// or out of date (posted after the stage change, or the idea was
  /// withdrawn). Students can't write the badge, so only the society does.
  void _syncBadge(CollabPost post) {
    if (widget.owner != null || _synced.contains(post.id)) return;
    final status = widget.idea.status;
    final expected =
        status == IdeaStatus.shortlisted || status == IdeaStatus.accepted
        ? status
        : null;
    if (post.societyStage == expected) return;
    _synced.add(post.id);
    VenturesService.syncSocietyStage(widget.idea, status);
  }

  Stream<CollabPost?>? _postStream() {
    final id = widget.idea.collabId;
    if (id != _streamId) {
      _streamId = id;
      _stream = id == null ? null : CollabBoard.post(id);
    }
    return _stream;
  }

  Future<void> _findTeammates() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TeamPostScreen(student: widget.owner!, idea: widget.idea),
      ),
    );
    if (message != null && mounted) {
      await showFlushbar(
        context,
        message,
        color: Colors.green.shade900,
        icon: Icons.check_circle_outline,
      );
    }
  }

  Future<void> _setRecruiting(CollabPost post, bool open) async {
    setState(() => _busy = true);
    try {
      await VenturesService.setRecruiting(post, open: open);
    } catch (_) {
      if (mounted) {
        await showFlushbar(
          context,
          'Could not update the post. Try again.',
          color: Colors.red.shade900,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final isOwner = widget.owner != null;
    final closedIdea = widget.idea.status == IdeaStatus.withdrawn;
    final stream = _postStream();

    if (stream == null) {
      // No team post. Only the student can start one, on a live idea.
      if (!isOwner || closedIdea) return const SizedBox.shrink();
      return _frame(
        t,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need people to build it with? Post it on the board and '
              'students with those skills can contact you.',
              style: EsType.body(t).copyWith(fontSize: 14, color: t.muted),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _findTeammates,
              child: const Text('Find teammates'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<CollabPost?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final post = snapshot.data;
        if (post != null) _syncBadge(post);
        if (post == null) {
          // Linked post was deleted.
          if (!isOwner || closedIdea) return const SizedBox.shrink();
          return _frame(
            t,
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your team post was deleted.',
                    style: EsType.body(t).copyWith(fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: _findTeammates,
                  child: const Text('Post again'),
                ),
              ],
            ),
          );
        }

        final closed = post.status == 'closed';
        final statusColor = post.isOpen
            ? t.moss
            : post.isRejected
            ? t.clay
            : t.muted;
        final statusText = closed
            ? 'Not recruiting'
            : isOwner
            ? post.statusLabel
            : post.isOpen
            ? 'Recruiting on the board'
            : post.statusLabel;
        return _frame(
          t,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    TextSpan(text: '   ${post.membersLine}'),
                  ],
                ),
                style: EsType.small(t),
              ),
              if (post.roles.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Needs ${post.roles.join(', ')}',
                  style: EsType.body(t).copyWith(fontSize: 14),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollabPostScreen(postId: post.id),
                      ),
                    ),
                    child: const Text('View post'),
                  ),
                  if (isOwner && !closedIdea && (post.isOpen || post.isPending))
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _setRecruiting(post, false),
                      child: const Text('Stop recruiting'),
                    ),
                  if (isOwner && !closedIdea && closed)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _setRecruiting(post, true),
                      child: const Text('Recruit again'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _frame(EsTokens t, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Team', style: EsType.heading(t)),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}
