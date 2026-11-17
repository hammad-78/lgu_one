import 'package:flutter/material.dart';
import 'package:lgu_one/collaboration/collab_actions.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/ventures/collab_post.dart';
import 'package:lgu_one/ventures/collab_post_screen.dart';

/// The board: approved team posts, with search and a category filter.
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<CollabPost>> _stream = CollabBoard.openPosts();
  final _search = TextEditingController();
  String _query = '';
  String? _category;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Categories on the board, most used first.
  List<String> _categories(List<CollabPost> posts) {
    final counts = <String, int>{};
    for (final p in posts) {
      final c = p.category.trim();
      if (c.isNotEmpty) counts[c] = (counts[c] ?? 0) + 1;
    }
    final list = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = EsTokens.of(context);
    final wide = isWideWeb(context);
    return StreamBuilder<List<CollabPost>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Message(
            'The board could not be loaded. Check your connection and open '
            'this page again.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!;
        final categories = _categories(all);
        final category = categories.contains(_category) ? _category : null;
        final words = _query.toLowerCase().split(RegExp(r'\s+'))
          ..removeWhere((w) => w.isEmpty);
        final posts = all.where((p) {
          if (category != null && p.category.trim() != category) return false;
          final text = p.searchText;
          return words.every(text.contains);
        }).toList();

        final header = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teams looking for people', style: EsType.title(t)),
                  const SizedBox(height: 4),
                  Text(
                    all.isEmpty
                        ? 'No open teams yet'
                        : '${all.length} open on the board',
                    style: EsType.small(t),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => CollabActions.startCreate(context),
              child: const Text('Post a team'),
            ),
          ],
        );

        final filters = <Widget>[
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by project, skill or role',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
              filled: true,
              fillColor: t.surface,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (categories.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final c in categories)
                    _CategoryChip(
                      label: c,
                      selected: category == c,
                      onTap: () =>
                          setState(() => _category = category == c ? null : c),
                    ),
                ],
              ),
            ),
          ],
        ];

        final Widget results;
        if (all.isEmpty) {
          results = Text(
            'When a student posts a team and an admin approves it, it shows '
            'up here. Post yours to find teammates.',
            style: EsType.body(t).copyWith(color: t.muted),
          );
        } else if (posts.isEmpty) {
          results = Text(
            'No teams match. Try another word or category.',
            style: EsType.body(t).copyWith(color: t.muted),
          );
        } else {
          results = Column(
            children: [for (final p in posts) CollabPostTile(post: p)],
          );
        }

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 32 : 20,
            vertical: wide ? 36 : 24,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 20),
                    ...filters,
                    const SizedBox(height: 20),
                    results,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? t.moss : t.muted,
        ),
        backgroundColor: Colors.transparent,
        selectedColor: t.moss.withValues(alpha: 0.12),
        side: BorderSide(color: selected ? t.moss : t.rule),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// One team in a list: title, society badge, size and the roles it needs.
/// [showStatus] puts the owner's view of approval in the meta line.
class CollabPostTile extends StatelessWidget {
  final CollabPost post;
  final bool showStatus;
  const CollabPostTile({
    super.key,
    required this.post,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final meta = <InlineSpan>[
      if (showStatus)
        TextSpan(
          text: '${post.statusLabel}   ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: post.isOpen
                ? t.moss
                : post.isRejected
                ? t.clay
                : t.muted,
          ),
        ),
      if (post.category.isNotEmpty) TextSpan(text: '${post.category}   '),
      TextSpan(text: post.membersLine),
    ];
    return EsPanel(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CollabPostScreen(postId: post.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EsType.heading(
                    t,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                relativeTime(post.createdAt),
                style: EsType.small(t).copyWith(fontSize: 12),
              ),
            ],
          ),
          if (post.societyStage != null) ...[
            const SizedBox(height: 4),
            SocietyBadge(stage: post.societyStage!),
          ],
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: meta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EsType.small(t),
          ),
          if (post.roles.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Needs ${post.roles.join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EsType.body(t).copyWith(fontSize: 14, color: t.ink),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Shortlisted by E-Society" / "Backed by E-Society", in the accent.
class SocietyBadge extends StatelessWidget {
  final IdeaStatus stage;
  const SocietyBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final label = stage == IdeaStatus.accepted
        ? 'Backed by E-Society'
        : 'Shortlisted by E-Society';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_outlined, size: 15, color: t.moss),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: t.moss,
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: EsType.body(EsTokens.of(context)),
        ),
      ),
    );
  }
}
