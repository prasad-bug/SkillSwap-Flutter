import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/skill.dart';
import '../../features/skills/providers/skill_providers.dart';

/// Skill listing card matching the approved Stitch design HTML.
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

    // Resolve owner via provider if not passed
    final ownerAsync = ref.watch(skillOwnerProvider(skill.ownerId));
    final owner = ownerAsync.asData?.value;
    final effectiveOwnerName = ownerName ?? owner?.name ?? 'Teacher';
    final effectiveOwnerAvatarUrl = ownerAvatarUrl ?? owner?.avatarUrl;
    final effectiveRole = owner?.bio.isNotEmpty == true
        ? owner!.bio
        : (owner?.location.isNotEmpty == true ? owner!.location : 'Instructor');

    return Semantics(
      label: '${skill.title} skill by $effectiveOwnerName',
      button: true,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap ?? () => context.push('/skills/${skill.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Card Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teacher row & Availability Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final hasValidAvatar = effectiveOwnerAvatarUrl != null &&
                                effectiveOwnerAvatarUrl.trim().isNotEmpty &&
                                (effectiveOwnerAvatarUrl.startsWith('http://') ||
                                    effectiveOwnerAvatarUrl.startsWith('https://'));
                            return CircleAvatar(
                              radius: 20,
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: hasValidAvatar
                                  ? CachedNetworkImageProvider(effectiveOwnerAvatarUrl)
                                  : null,
                              child: !hasValidAvatar
                                  ? Text(
                                      effectiveOwnerName.isNotEmpty
                                          ? effectiveOwnerName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                effectiveOwnerName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                effectiveRole,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildAvailabilityBadge(cs, theme),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category & Level Chips
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skill.category.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skill.level.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      skill.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      skill.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Bottom integrated footer ribbon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Star rating + count
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: cs.tertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          skill.avgRating.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${skill.ratingCount})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ),

                    // "Request Swap" action button
                    Material(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onTap ?? () => context.push('/skills/${skill.id}'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 14,
                                color: cs.onPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Request Swap',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge(ColorScheme cs, ThemeData theme) {
    final (badgeBg, badgeText, dotColor, label) = switch (skill.availability) {
      AvailabilityStatus.available => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
          cs.secondary,
          'Available',
        ),
      AvailabilityStatus.limited => (
          cs.tertiaryContainer.withValues(alpha: 0.2),
          cs.tertiary,
          cs.tertiary,
          'Limited',
        ),
      AvailabilityStatus.unavailable => (
          cs.errorContainer,
          cs.onErrorContainer,
          cs.error,
          'Unavailable',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeText,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
