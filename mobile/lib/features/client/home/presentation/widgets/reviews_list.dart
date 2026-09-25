import 'package:flutter/material.dart';
import 'package:mongez/features/client/home/data/models/rating_model.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/widgets/skeletons/skeleton_review_tile.dart';

class ReviewsList extends StatelessWidget {
  final List<RatingModel> ratings;
  final bool isLoading;
  final String? errorMessage;

  const ReviewsList({
    super.key,
    required this.ratings,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final lang = S.of(context);

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          children: [
            SkeletonReviewTile(),
            SkeletonReviewTile(),
            SkeletonReviewTile(),
          ],
        ),
      );
    }
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            lang.errorOccurred,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: tt.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    if (ratings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            lang.noReviews,
            style: tt.bodyMedium?.copyWith(
              color: tt.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      itemCount: ratings.length,
      itemBuilder: (context, index) {
        final rating = ratings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      child: Text(
                        (rating.clientName ?? '?')[0].toUpperCase(),
                        style: tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rating.clientName ?? lang.anonymous,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: Colors.amber.shade700,
                        );
                      }),
                    ),
                  ],
                ),
                if (rating.review.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    rating.review,
                    style: tt.bodySmall?.copyWith(
                      height: 1.5,
                      color: tt.bodySmall?.color?.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
