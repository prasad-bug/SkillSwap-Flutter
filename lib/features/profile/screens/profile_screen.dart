import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/empty_error_states.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/app_user.dart';

final _profileUserProvider =
    FutureProvider.family<AppUser?, String?>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  if (userId == null) return repo.getCurrentUser();
  return repo.getUserById(userId);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_profileUserProvider(userId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.asData?.value?.id ?? '';

    return userAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: ErrorState(message: e.toString())),
      data: (user) {
        if (user == null) return const Scaffold(body: EmptyState(title: 'User not found'));
        final isCurrentUser = user.id == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: Text(isCurrentUser ? 'My Profile' : user.name),
            actions: [
              if (isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/profile/edit'),
                ),
              if (isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () async {
                    await ref.read(userRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(user: user, isCurrentUser: isCurrentUser),
              ),
              SliverToBoxAdapter(
                child: _SkillsSection(user: user),
              ),
              SliverToBoxAdapter(
                child: _ReviewsSection(userId: user.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.isCurrentUser});
  final AppUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.spaceLG),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: cs.primary,
            child: Text(
              user.initials,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceMD),
          Text(user.name, style: theme.textTheme.headlineSmall),
          if (user.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(user.location, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ],
          if (user.ratingCount > 0) ...[
            const SizedBox(height: AppConstants.spaceSM),
            RatingStars(rating: user.avgRating, count: user.ratingCount),
          ],
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceMD),
            Text(
              user.bio,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppConstants.spaceMD),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(label: 'Skills', value: user.offeredSkillIds.length.toString()),
              _StatChip(label: 'Rating', value: user.avgRating.toStringAsFixed(1)),
              _StatChip(label: 'Sessions', value: user.ratingCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SkillsSection extends ConsumerWidget {
  const _SkillsSection({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Offered Skills', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spaceSM),
          if (user.offeredSkillIds.isEmpty)
            Text('No skills offered yet', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          else
            ...user.offeredSkillIds.map((sid) => _SkillTile(skillId: sid)),
          if (user.wantedSkills.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceMD),
            Text('Wants to Learn', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spaceSM),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: user.wantedSkills.map((s) => Chip(label: Text(s))).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillTile extends ConsumerWidget {
  const _SkillTile({required this.skillId});
  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Import from skill providers
    final skillAsync = ref.watch(
        _skillForProfileProvider(skillId));
    return skillAsync.when(
      data: (skill) {
        if (skill == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(skill.title, style: theme.textTheme.titleSmall),
            subtitle: Text(skill.category.label, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/skills/${skill.id}'),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

final _skillForProfileProvider = FutureProvider.family((ref, String skillId) async {
  return ref.watch(skillRepositoryProvider).getSkillById(skillId);
});

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(_userRatingsProvider(userId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviews', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spaceSM),
          ratingsAsync.when(
            data: (ratings) {
              if (ratings.isEmpty) {
                return Text('No reviews yet.', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant));
              }
              return Column(
                children: ratings.take(5).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spaceMD),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primaryContainer,
                        child: Text(r.fromUserName.isNotEmpty ? r.fromUserName[0].toUpperCase() : '?',
                            style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.fromUserName, style: theme.textTheme.titleSmall),
                            RatingStars(rating: r.stars.toDouble(), showCount: false, size: 12),
                            const SizedBox(height: 4),
                            Text(r.review, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

final _userRatingsProvider = FutureProvider.family((ref, String userId) async {
  return ref.watch(ratingRepositoryProvider).getRatingsForUser(userId);
});
