import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/skill.dart';
import '../theme/category_theme_extension.dart';
import '../constants/app_constants.dart';
import 'availability_badge.dart';
import 'rating_stars.dart';

/// Skill listing card shown in grids and lists.
class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.skill,
    this.ownerName,
    this.ownerAvatarUrl,
    this.onTap,
  });

  final Skill skill;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catExt = CategoryThemeExtension.of(context);
    final catColor = catExt.colorForCategory(skill.category.name);

    return Semantics(
      label: '${skill.title} skill by ${ownerName ?? "unknown"}',
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 16dp radius
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap ?? () => context.push('/skills/${skill.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teacher row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primaryContainer,
                      backgroundImage: ownerAvatarUrl != null ? CachedNetworkImageProvider(ownerAvatarUrl!) : null,
                      child: ownerAvatarUrl == null
                          ? Text(
                              ownerName?.isNotEmpty == true ? ownerName![0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 16,
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ownerName ?? 'Unknown Teacher',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Teacher', // Assuming role is teacher, or use a generic one if role not provided
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AvailabilityBadge(status: skill.availability, compact: false), // badge on right
                  ],
                ),
                const SizedBox(height: 16),
                // Chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill.category.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: catColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill.level.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title and description
                Text(
                  skill.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  skill.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Spacer(),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RatingStars(
                      rating: skill.avgRating,
                      count: skill.ratingCount,
                    ),
                    FilledButton.icon(
                      onPressed: onTap ?? () => context.push('/skills/${skill.id}'),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Request Swap'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
