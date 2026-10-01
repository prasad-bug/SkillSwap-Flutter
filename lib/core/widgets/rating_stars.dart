import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// Compact star + numeric rating + count display.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.count,
    this.size = 14.0,
    this.showCount = true,
  });

  final double rating;
  final int? count;
  final double size;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Rating $rating out of 5${count != null ? ', $count ratings' : ''}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBarIndicator(
            rating: rating,
            itemSize: size,
            itemBuilder: (_, __) => const Icon(
              Icons.star_rounded,
              color: Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (showCount && count != null) ...[
            const SizedBox(width: 2),
            Text(
              '($count)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
