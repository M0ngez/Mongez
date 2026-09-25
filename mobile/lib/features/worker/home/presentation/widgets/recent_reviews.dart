import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/shared/workers/data/models/worker_stats.dart';
import 'package:mongez/features/worker/home/presentation/cubit/worker_stats_cubit.dart';
import 'package:mongez/features/worker/home/presentation/screens/worker_reviews_screen.dart';
import 'package:mongez/generated/l10n.dart';

class RecentReviews extends StatelessWidget {
  const RecentReviews({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerStatsCubit, WorkerStatsState>(
      builder: (ctx, state) {
        if (state is! WorkerStatsSuccess) return const SizedBox.shrink();
        final reviews = state.stats.recentReviews;
        if (reviews.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(ctx);
        final lang = S.of(ctx);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.recentReviews,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final WorkerStatsReview r in reviews) ReviewTile(review: r),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerReviewsScreen(
                        workerId: state.stats.profileId,
                      ),
                    ),
                  ),
                  child: Text(lang.viewAll),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReviewTile extends StatelessWidget {
  final WorkerStatsReview review;
  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Text(
                  review.displayName.isNotEmpty
                      ? review.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < review.stars;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          if (review.review.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.review,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
