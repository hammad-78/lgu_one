import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';

/// E-Society reviews on a collaboration: the average, then each review.
class CollabReviewList extends StatelessWidget {
  final List<CollabReview> reviews;
  const CollabReviewList({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final avg =
        reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;
    final count = reviews.length == 1
        ? '1 review'
        : '${reviews.length} reviews';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback from the Entrepreneurship Society',
          style: EsType.heading(t).copyWith(fontSize: 14.5),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            StarRow(avg.round(), size: 16),
            const SizedBox(width: 6),
            Text(
              '${avg.toStringAsFixed(1)} from $count',
              style: EsType.small(t),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final r in reviews)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: t.rule, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.comment.isNotEmpty)
                  Text(r.comment, style: EsType.body(t).copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(r.reviewerName, style: EsType.small(t)),
                    const SizedBox(width: 6),
                    StarRow(r.rating, size: 12),
                  ],
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
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CollabReviewList(reviews: reviews),
        );
      },
    );
  }
}
