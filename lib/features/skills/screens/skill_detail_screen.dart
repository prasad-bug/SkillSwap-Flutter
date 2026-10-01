import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/availability_badge.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/profile_card.dart';
import '../../../core/widgets/empty_error_states.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/category_theme_extension.dart';
import '../../../data/models/skill.dart';
import '../providers/skill_providers.dart';

class SkillDetailScreen extends ConsumerWidget {
  const SkillDetailScreen({super.key, required this.skillId});
  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillAsync = ref.watch(skillByIdProvider(skillId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return skillAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: e.toString()),
      ),
      data: (skill) {
        if (skill == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(title: 'Skill not found'),
          );
        }

        final catExt = CategoryThemeExtension.of(context);
        final catColor = catExt.colorForCategory(skill.category.name);
        final catIcon =
            CategoryThemeExtension.iconForCategory(skill.category.name);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [catColor, cs.surfaceContainerHighest],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cs.surface.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(catIcon, size: 40, color: cs.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            skill.category.label,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spaceMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + availability
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              skill.title,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AvailabilityBadge(status: skill.availability),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spaceSM),
                      // Level + duration
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(skill.level.label),
                            avatar: const Icon(Icons.school_outlined, size: 16),
                          ),
                          Chip(
                            label: Text('${skill.sessionDurationMins} min session'),
                            avatar: const Icon(Icons.timer_outlined, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spaceSM),
                      // Rating
                      if (skill.ratingCount > 0)
                        RatingStars(
                            rating: skill.avgRating, count: skill.ratingCount),
                      const SizedBox(height: AppConstants.spaceMD),
                      // Tags
                      if (skill.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: skill.tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(t,
                                        style: theme.textTheme.bodySmall),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: AppConstants.spaceMD),
                      ],
                      const Divider(),
                      // Description
                      Text('About this skill',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppConstants.spaceSM),
                      Text(skill.description, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppConstants.spaceMD),
                      const Divider(),
                      // Owner
                      Text('Instructor', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppConstants.spaceSM),
                      _OwnerSection(ownerId: skill.ownerId),
                      const Divider(),
                      // Reviews
                      Text('Reviews', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppConstants.spaceSM),
                      _ReviewsSection(skillId: skillId),
                      const SizedBox(height: 100), // space for CTA
                    ],
                  ),
                ),
              ),
            ],
          ),
          // CTA Bottom bar
          bottomNavigationBar: _SkillDetailCTABar(skillId: skillId),
        );
      },
    );
  }
}

class _OwnerSection extends ConsumerWidget {
  const _OwnerSection({required this.ownerId});
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(skillOwnerProvider(ownerId));
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return ProfileCard(
          user: user,
          onTap: () => context.push('/profile?userId=${user.id}'),
          trailing: const Icon(Icons.chevron_right_rounded),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.skillId});
  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(skillRatingsProvider(skillId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final df = DateFormat('MMM d, yyyy');

    return ratingsAsync.when(
      data: (ratings) {
        if (ratings.isEmpty) {
          return Text(
            'No reviews yet. Be the first!',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          );
        }
        return Column(
          children: ratings.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spaceMD),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      r.fromUserName.isNotEmpty
                          ? r.fromUserName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.fromUserName,
                                style: theme.textTheme.titleSmall),
                            Text(df.format(r.createdAt),
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RatingStars(
                            rating: r.stars.toDouble(),
                            showCount: false,
                            size: 12),
                        const SizedBox(height: 4),
                        Text(r.review, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SkillDetailCTABar extends ConsumerWidget {
  const _SkillDetailCTABar({required this.skillId});
  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillAsync = ref.watch(skillByIdProvider(skillId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.asData?.value?.id ?? '';

    return skillAsync.when(
      data: (skill) {
        if (skill == null) return const SizedBox.shrink();
        final isOwner = skill.ownerId == currentUserId;

        return Container(
          padding: const EdgeInsets.fromLTRB(AppConstants.spaceMD,
              AppConstants.spaceSM, AppConstants.spaceMD, AppConstants.spaceMD),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (!isOwner) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Message'),
                      onPressed: () async {
                        final chatRepo = ref.read(chatRepositoryProvider);
                        final userRepo = ref.read(userRepositoryProvider);
                        final thread = await chatRepo.getOrCreateThread(
                            currentUserId, skill.ownerId);
                        final owner = await userRepo.getUserById(skill.ownerId);
                        if (context.mounted) {
                          context.push(
                            '/chats/${thread.id}',
                            extra: {
                              'otherUserName': owner?.name ?? '',
                              'otherUserId': skill.ownerId,
                            },
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Book Session'),
                      onPressed:
                          skill.availability == AvailabilityStatus.unavailable
                              ? null
                              : () => context.push('/skills/$skillId/book'),
                    ),
                  ),
                ] else
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('This is your skill'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
