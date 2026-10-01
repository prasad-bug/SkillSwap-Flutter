import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/skill.dart';
import '../../features/skills/providers/skill_providers.dart';
import '../theme/category_theme_extension.dart';
import '../constants/app_constants.dart';
import 'availability_badge.dart';
import 'rating_stars.dart';

/// Skill listing card shown in carousels, grids and lists.
class SkillCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catExt = CategoryThemeExtension.of(context);
    final catColor = catExt.colorForCategory(skill.category.name);

    // Resolve owner via provider if not explicitly passed
    final ownerAsync = ref.watch(skillOwnerProvider(skill.ownerId));
    final owner = ownerAsync.asData?.value;
    final effectiveOwnerName = ownerName ?? owner?.name ?? 'Teacher';
    final effectiveOwnerAvatarUrl = ownerAvatarUrl ?? owner?.avatarUrl;

    return Semantics(
      label: '${skill.title} skill by $effectiveOwnerName',
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                      backgroundImage: effectiveOwnerAvatarUrl != null
                          ? CachedNetworkImageProvider(effectiveOwnerAvatarUrl)
                          : null,
                      child: effectiveOwnerAvatarUrl == null
                          ? Text(
                              effectiveOwnerName.isNotEmpty
                                  ? effectiveOwnerName[0].toUpperCase()
                                  : '?',
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
                            effectiveOwnerName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            owner?.location.isNotEmpty == true
                                ? owner!.location
                                : 'Instructor',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AvailabilityBadge(status: skill.availability, compact: false),
                  ],
                ),
                const SizedBox(height: 16),

                // Category & Level Chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill.category.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: catColor.withValues(alpha: 0.9),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  skill.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Spacer(),

                // Footer: Rating on left, "Request Swap" filled button on right
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
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
