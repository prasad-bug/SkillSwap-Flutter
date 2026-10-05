import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/skill.dart';
import '../../../data/models/booking.dart';
import '../../skills/providers/skill_providers.dart';
import '../../booking/providers/booking_providers.dart';

final _profileUserProvider =
    FutureProvider.family<AppUser?, String?>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  if (userId == null) return repo.getCurrentUser();
  return repo.getUserById(userId);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0;
  bool _showEmptyView = false;
  bool _showToast = false;
  Timer? _toastTimer;

  void _showShareToast() {
    setState(() => _showToast = true);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(_profileUserProvider(widget.userId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.asData?.value?.id ?? '';
    final cs = Theme.of(context).colorScheme;

    return userAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        final isCurrentUser = user.id == currentUserId;

        return Scaffold(
          backgroundColor: cs.surface,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _ProfileAppBar(user: user),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 24,
                        bottom: 96,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHeaderModule(
                            user: user,
                            isCurrentUser: isCurrentUser,
                            onShare: _showShareToast,
                          ),
                          const SizedBox(height: 32),
                          _TeachingPortfolioSection(
                            user: user,
                            isCurrentUser: isCurrentUser,
                          ),
                          const SizedBox(height: 32),
                          _WishlistSection(),
                          const SizedBox(height: 32),
                          _MyBookingsSection(
                            selectedTab: _selectedTab,
                            showEmptyView: _showEmptyView,
                            onTabChanged: (idx) {
                              setState(() {
                                _selectedTab = idx;
                                _showEmptyView = false;
                              });
                            },
                            onToggleEmptyView: () {
                              setState(() {
                                _showEmptyView = !_showEmptyView;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Toast
              if (_showToast)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF213145), // inverseSurface approx
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: cs.secondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Profile link copied to clipboard!',
                            style: TextStyle(
                              color: Color(0xFFEAF1FF),
                              fontSize: 12,
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
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileAppBar extends ConsumerWidget {
  const _ProfileAppBar({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // In design, this is standard app bar with brand icon and small "Profile"
    return SliverAppBar(
      pinned: true,
      backgroundColor: cs.surface.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sync_alt_rounded,
              color: cs.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SkillSwap',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Profile',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: cs.onSurfaceVariant,
            size: 24,
          ),
          onPressed: () => ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Coming soon!'))),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              backgroundImage: safeNetworkImageProvider(user.avatarUrl),
              child: safeNetworkImageProvider(user.avatarUrl) == null
                  ? Text(
                      user.initials,
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header Module
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeaderModule extends StatelessWidget {
  const _ProfileHeaderModule({
    required this.user,
    required this.isCurrentUser,
    required this.onShare,
  });

  final AppUser user;
  final bool isCurrentUser;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final handle = '@${user.name.replaceAll(' ', '_').toLowerCase()}';
    final location =
        user.location.isNotEmpty ? user.location : 'San Francisco, CA · PST';
    final imgUrl = user.avatarUrl ?? 'https://i.pravatar.cc/150?img=16';

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner
          Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.secondaryContainer.withValues(alpha: 0.3),
                  cs.primaryFixed.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 8,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active Member',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Details & Avatar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -24),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: cs.surfaceContainer,
                            backgroundImage: safeNetworkImageProvider(imgUrl),
                            child: safeNetworkImageProvider(imgUrl) == null
                                ? Text(
                                    user.initials,
                                    style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLowest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Buttons
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: onShare,
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            onTap: () => context.push('/profile/edit'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Name & Location
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            handle,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stats Bar
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '24',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Swaps Done',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 36,
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.3)),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded,
                                          size: 16,
                                          color: cs.tertiaryContainer),
                                      const SizedBox(width: 4),
                                      Text(
                                        '4.95',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '38 reviews',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 36,
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.3)),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt_rounded,
                                          size: 16, color: cs.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '6',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Swap Credits',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teaching Portfolio Section (Dynamic & Interactive)
// ─────────────────────────────────────────────────────────────────────────────
class _TeachingPortfolioSection extends ConsumerWidget {
  const _TeachingPortfolioSection({
    required this.user,
    required this.isCurrentUser,
  });

  final AppUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final skillsAsync = ref.watch(userTeachingSkillsProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Skills I Teach',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (isCurrentUser)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openAddSkillModal(context, ref, user),
                  borderRadius: BorderRadius.circular(100),
                  child: Ink(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: cs.primaryFixed,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: cs.onPrimaryFixed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Add Skill',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onPrimaryFixed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        skillsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Error loading skills: $e'),
          ),
          data: (skills) {
            if (skills.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 42,
                      color: cs.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No skills listed to teach yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your knowledge and earn swap credits!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAddSkillModal(context, ref, user),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Your First Skill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Column(
              children: skills.map((skill) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TeachingSkillCard(
                    skill: skill,
                    isCurrentUser: isCurrentUser,
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Skill'),
                          content: Text('Are you sure you want to remove "${skill.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: cs.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(skillRepositoryProvider).deleteSkill(skill.id);
                        ref.invalidate(userTeachingSkillsProvider(user.id));
                        ref.invalidate(skillsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${skill.title}" removed')),
                          );
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _openAddSkillModal(BuildContext context, WidgetRef ref, AppUser user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddSkillModalSheet(user: user),
    );
  }
}

class _TeachingSkillCard extends StatelessWidget {
  const _TeachingSkillCard({
    required this.skill,
    required this.isCurrentUser,
    this.onDelete,
  });

  final Skill skill;
  final bool isCurrentUser;
  final VoidCallback? onDelete;

  IconData _getCategoryIcon(SkillCategory category) {
    switch (category) {
      case SkillCategory.technology:
        return Icons.code_rounded;
      case SkillCategory.music:
        return Icons.music_note_rounded;
      case SkillCategory.language:
        return Icons.translate_rounded;
      case SkillCategory.art:
        return Icons.palette_rounded;
      case SkillCategory.fitness:
        return Icons.fitness_center_rounded;
      case SkillCategory.cooking:
        return Icons.restaurant_rounded;
      case SkillCategory.business:
        return Icons.business_center_rounded;
      case SkillCategory.other:
        return Icons.auto_awesome_rounded;
    }
  }

  Color _getCategoryColor(BuildContext context, SkillCategory category) {
    final cs = Theme.of(context).colorScheme;
    switch (category) {
      case SkillCategory.technology:
        return cs.primary;
      case SkillCategory.music:
        return const Color(0xFF71F8E4);
      case SkillCategory.language:
        return const Color(0xFF9E86FF);
      case SkillCategory.art:
        return const Color(0xFFFF7EAE);
      case SkillCategory.fitness:
        return const Color(0xFFFF9E45);
      case SkillCategory.cooking:
        return const Color(0xFFFF6D60);
      case SkillCategory.business:
        return const Color(0xFF4E9F3D);
      case SkillCategory.other:
        return cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _getCategoryColor(context, skill.category);
    final icon = _getCategoryIcon(skill.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/skills/${skill.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            skill.title,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(100),
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
                    const SizedBox(height: 4),
                    Text(
                      skill.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrentUser && onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: cs.error.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Remove skill',
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: cs.tertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        skill.avgRating > 0
                            ? skill.avgRating.toStringAsFixed(1)
                            : 'New',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Skill Modal Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddSkillModalSheet extends ConsumerStatefulWidget {
  const _AddSkillModalSheet({required this.user});
  final AppUser user;

  @override
  ConsumerState<_AddSkillModalSheet> createState() =>
      _AddSkillModalSheetState();
}

class _AddSkillModalSheetState extends ConsumerState<_AddSkillModalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();

  SkillCategory _category = SkillCategory.technology;
  SkillLevel _level = SkillLevel.intermediate;
  int _durationMins = 60;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final skillId = 'skill_${DateTime.now().millisecondsSinceEpoch}';
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final newSkill = Skill(
        id: skillId,
        ownerId: widget.user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        level: _level,
        availability: AvailabilityStatus.available,
        sessionDurationMins: _durationMins,
        tags: tags.isNotEmpty
            ? tags
            : [_category.label, _level.label, 'Live Session'],
        avgRating: 5.0,
        ratingCount: 1,
      );

      await ref.read(skillRepositoryProvider).saveSkill(newSkill);

      // Invalidate to refresh immediately
      ref.invalidate(userTeachingSkillsProvider(widget.user.id));
      ref.invalidate(skillsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Skill "${newSkill.title}" added to your profile!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add skill: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Teaching Skill',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'List a skill you can teach other learners',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Skill Title
                Text(
                  'Skill Title *',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Flutter Development, Acoustic Guitar...',
                    filled: true,
                    fillColor: cs.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a skill title';
                    }
                    if (val.trim().length < 3) {
                      return 'Skill title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Category Selection
                Text(
                  'Category *',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SkillCategory.values.map((cat) {
                    final selected = _category == cat;
                    return ChoiceChip(
                      label: Text(cat.label),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => _category = cat);
                      },
                      selectedColor: cs.primaryFixed,
                      labelStyle: TextStyle(
                        color: selected
                            ? cs.onPrimaryFixed
                            : cs.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Proficiency Level
                Text(
                  'Proficiency Level *',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: SkillLevel.values.map((lvl) {
                    final selected = _level == lvl;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(lvl.label)),
                          selected: selected,
                          onSelected: (val) {
                            if (val) setState(() => _level = lvl);
                          },
                          selectedColor: cs.primaryFixed,
                          labelStyle: TextStyle(
                            color: selected
                                ? cs.onPrimaryFixed
                                : cs.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Description
                Text(
                  'Description / What you will teach *',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Beginner friendly sessions covering fundamental concepts, hands-on practice, and answering your questions.',
                    filled: true,
                    fillColor: cs.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide a short description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Session Duration
                Text(
                  'Session Duration',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [30, 45, 60, 90].map((mins) {
                    final selected = _durationMins == mins;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text('$mins m')),
                          selected: selected,
                          onSelected: (val) {
                            if (val) setState(() => _durationMins = mins);
                          },
                          selectedColor: cs.secondaryContainer,
                          labelStyle: TextStyle(
                            color: selected
                                ? cs.onSecondaryContainer
                                : cs.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Tags
                Text(
                  'Tags (Optional, comma separated)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Coding, Mobile, Dart',
                    filled: true,
                    fillColor: cs.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: cs.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Publish Skill',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wishlist Section
// ─────────────────────────────────────────────────────────────────────────────
class _WishlistSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: cs.secondary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Skills I Want to Learn',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ],
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _WishChip(
                  icon: Icons.palette_outlined,
                  label: 'Figma & UI Design',
                  isPrimary: true),
              const _WishChip(icon: Icons.draw_outlined, label: 'Pottery'),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 16, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WishChip extends StatelessWidget {
  const _WishChip({
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isPrimary ? cs.onPrimaryContainer : cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPrimary ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Bookings Section (Dynamic & Real-time)
// ─────────────────────────────────────────────────────────────────────────────
class _MyBookingsSection extends ConsumerWidget {
  const _MyBookingsSection({
    required this.selectedTab,
    required this.showEmptyView,
    required this.onTabChanged,
    required this.onToggleEmptyView,
  });

  final int selectedTab;
  final bool showEmptyView;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onToggleEmptyView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bookingsAsync = ref.watch(userBookingsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return bookingsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Error loading bookings: $err'),
      ),
      data: (bookings) {
        final upcoming = bookings
            .where((b) =>
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.pending)
            .toList();
        final completed = bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
        final cancelled = bookings
            .where((b) => b.status == BookingStatus.cancelled)
            .toList();

        final currentList = selectedTab == 0
            ? upcoming
            : selectedTab == 1
                ? completed
                : cancelled;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Scheduled peer-to-peer exchanges',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.push('/bookings'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs with live counts
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Upcoming (${upcoming.length})',
                      isSelected: selectedTab == 0,
                      onTap: () => onTabChanged(0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Completed (${completed.length})',
                      isSelected: selectedTab == 1,
                      onTap: () => onTabChanged(1),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Cancelled (${cancelled.length})',
                      isSelected: selectedTab == 2,
                      onTap: () => onTabChanged(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (currentList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      selectedTab == 0
                          ? Icons.calendar_today_rounded
                          : selectedTab == 1
                              ? Icons.task_alt_rounded
                              : Icons.event_busy_rounded,
                      size: 40,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedTab == 0
                          ? 'No upcoming bookings'
                          : selectedTab == 1
                              ? 'No completed sessions yet'
                              : 'No cancelled bookings',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedTab == 0
                          ? 'Explore skills and book a session with a mentor!'
                          : selectedTab == 1
                              ? 'Completed sessions will appear here with review options.'
                              : 'Cancelled bookings will appear here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (selectedTab == 0) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/skills'),
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: const Text('Discover Skills'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Column(
                children: currentList.map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProfileBookingCard(
                      booking: booking,
                      currentUserId: currentUser?.id ?? '',
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  )
                ],
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ProfileBookingCard extends ConsumerWidget {
  const _ProfileBookingCard({
    required this.booking,
    required this.currentUserId,
  });

  final Booking booking;
  final String currentUserId;

  Color _getStatusColor(BuildContext context, BookingStatus status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case BookingStatus.confirmed:
        return cs.primary;
      case BookingStatus.completed:
        return const Color(0xFF10B981);
      case BookingStatus.cancelled:
        return cs.error;
      case BookingStatus.pending:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = _getStatusColor(context, booking.status);
    final isTeacher = booking.teacherId == currentUserId;
    final dateStr = DateFormat.yMMMd().format(booking.dateTime);
    final timeStr = DateFormat.jm().format(booking.dateTime);

    final displayTitle = booking.skillTitle.isNotEmpty
        ? booking.skillTitle
        : 'Skill Session';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Icon(
                  isTeacher
                      ? Icons.school_rounded
                      : Icons.lightbulb_outline_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTeacher
                          ? 'Teaching session • ${booking.durationMins} mins'
                          : 'Learning session • ${booking.durationMins} mins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  booking.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '$dateStr · $timeStr',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (booking.status == BookingStatus.confirmed ||
              booking.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Booking'),
                          content: const Text(
                              'Are you sure you want to cancel this scheduled session?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Keep Booking'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: cs.error),
                              child: const Text('Cancel Session'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(bookingRepositoryProvider)
                            .cancelBooking(booking.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Session cancelled successfully'),
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => context.push('/chats'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
          if (booking.status == BookingStatus.completed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/rating/${booking.id}'),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: const Text('Rate This Session'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

