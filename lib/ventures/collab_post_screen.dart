import 'package:flutter/material.dart';
import 'package:lgu_one/collaboration/collab_actions.dart';
import 'package:lgu_one/collaboration/collab_owner.dart';
import 'package:lgu_one/esociety/collab_reviews.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/ventures/collab_post.dart';
import 'package:lgu_one/ventures/explore_tab.dart';
import 'package:lgu_one/ventures/ventures_service.dart';

/// One team post: what it is, who it needs, society feedback, and a way to
/// get in touch. The owner can edit or delete it here.
class CollabPostScreen extends StatefulWidget {
  final String postId;
  const CollabPostScreen({super.key, required this.postId});

  @override
  State<CollabPostScreen> createState() => _CollabPostScreenState();
}

class _CollabPostScreenState extends State<CollabPostScreen> {
  late final Stream<CollabPost?> _stream = CollabBoard.post(widget.postId);
  bool _busy = false;

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
    return StreamBuilder<CollabPost?>(
      stream: _stream,
      builder: (context, snapshot) {
        final post = snapshot.data;
        final mine = post != null && CollabOwner.isMine(post.info);
        // Older posts have no owner; whoever has the secret key can manage
        // them, so the menu shows for everyone and asks for the key.
        final canManage =
            post != null && (mine || CollabOwner.isLegacy(post.info));
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (canManage)
                PopupMenuButton<String>(
                  tooltip: 'Post actions',
                  onSelected: (action) => _onAction(action, post),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          body: SafeArea(
            child: snapshot.hasError
                ? _center(
                    'This post could not be loaded. Check your connection.',
                    t,
                  )
                : snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : post == null
                ? _center('This post was removed.', t)
                : _body(post, mine, t),
          ),
        );
      },
    );
  }

  void _onAction(String action, CollabPost post) {
    if (action == 'edit') {
      CollabActions.asOwner(
        context,
        post.info,
        () => CollabActions.showEdit(context, post.id, post.info),
      );
    } else if (action == 'delete') {
      CollabActions.asOwner(
        context,
        post.info,
        () => CollabActions.confirmDelete(
          context,
          post.id,
          ideaId: CollabOwner.isMine(post.info) ? post.ideaId : null,
        ),
      );
    }
  }

  Widget _center(String text, EsTokens t) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center, style: EsType.body(t)),
    ),
  );

  Widget _body(CollabPost post, bool mine, EsTokens t) {
    final wide = isWideWeb(context);
    final posted = [
      if (post.ownerName.isNotEmpty) 'Posted by ${post.ownerName}',
      if (post.createdAt != null) relativeTime(post.createdAt),
    ].join(' · ');

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 32 : 20,
        vertical: wide ? 28 : 16,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: EsType.title(t)),
                if (posted.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(posted, style: EsType.small(t)),
                ],
                if (post.societyStage != null) ...[
                  const SizedBox(height: 8),
                  SocietyBadge(stage: post.societyStage!),
                ],
                if (mine && !post.isOpen) ...[
                  const SizedBox(height: 16),
                  EsPanel(
                    child: Text(
                      post.isPending
                          ? 'Waiting for approval. Other students see it '
                                'once an admin approves it.'
                          : post.isRejected
                          ? 'An admin did not approve this post, so it is '
                                'not on the board.'
                          : post.status == 'closed'
                          ? 'You stopped recruiting, so it is off the board.'
                          : 'Not on the board (${post.statusLabel}).',
                      style: EsType.body(t).copyWith(
                        fontSize: 14,
                        color: post.isRejected ? t.clay : t.ink,
                      ),
                    ),
                  ),
                ],
                if (post.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(post.description.trim(), style: EsType.body(t)),
                ],
                const SizedBox(height: 20),
                FactList([
                  ('Category', post.category),
                  ('Team', post.membersLine),
                  ('Looking for', post.roles.join(', ')),
                ]),
                CollabSocietyReviews(collabId: post.id),
                const SizedBox(height: 28),
                if (!mine && post.whatsapp.trim().isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          CollabActions.contact(context, post.whatsapp),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('Contact on WhatsApp'),
                    ),
                  ),
                if (mine)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _onAction('edit', post),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(foregroundColor: t.clay),
                          onPressed: () => _onAction('delete', post),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                if (mine &&
                    (post.isOpen || post.isPending || post.status == 'closed'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () =>
                                  _setRecruiting(post, post.status == 'closed'),
                        child: Text(
                          post.status == 'closed'
                              ? 'Recruit again (needs approval)'
                              : 'Stop recruiting',
                        ),
                      ),
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
