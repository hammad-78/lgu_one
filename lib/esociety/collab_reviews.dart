import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';

/// List of E-Society reviews on a collaboration.
class CollabReviewList extends StatelessWidget {
  final List<CollabReview> reviews;
  const CollabReviewList({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg =
        reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'E-Society feedback',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            StarRow(avg.round(), size: 15),
            const SizedBox(width: 4),
            Text(
              '${avg.toStringAsFixed(1)} (${reviews.length})',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final r in reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StarRow(r.rating, size: 13),
                  ],
                ),
                if (r.comment.isNotEmpty)
                  Text(
                    r.comment,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// E-Society feedback on a collaboration card, for students. Shows nothing
/// until a society member has reviewed it.
class CollabSocietyReviews extends StatefulWidget {
  final String collabId;
  const CollabSocietyReviews({super.key, required this.collabId});

  @override
  State<CollabSocietyReviews> createState() => _CollabSocietyReviewsState();
}

class _CollabSocietyReviewsState extends State<CollabSocietyReviews> {
  late final Stream<List<CollabReview>> _stream = EsocietyService.instance
      .collabReviews(widget.collabId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CollabReview>>(
      stream: _stream,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <CollabReview>[];
        if (reviews.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CollabReviewList(reviews: reviews),
        );
      },
    );
  }
}
