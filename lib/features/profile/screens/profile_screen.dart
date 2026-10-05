import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/app_user.dart';

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
                          _TeachingPortfolioSection(),
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
          onPressed: () {},
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
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
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
    final location = user.location.isNotEmpty ? user.location : 'San Francisco, CA · PST';
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
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
                            backgroundImage: CachedNetworkImageProvider(imgUrl),
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
                              Icon(Icons.location_on_outlined, size: 14, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Swaps Done',
                                    style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 36, color: cs.outlineVariant.withValues(alpha: 0.3)),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 16, color: cs.tertiaryContainer),
                                      const SizedBox(width: 4),
                                      Text(
                                        '4.95',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '38 reviews',
                                    style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 36, color: cs.outlineVariant.withValues(alpha: 0.3)),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt_rounded, size: 16, color: cs.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '6',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Swap Credits',
                                    style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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
  const _ActionButton({required this.icon, required this.label, required this.onTap});
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
// Teaching Portfolio Section
// ─────────────────────────────────────────────────────────────────────────────
class _TeachingPortfolioSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('Skills I Teach', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cs.primaryFixed,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 18, color: cs.onPrimaryFixed),
                  const SizedBox(width: 4),
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
          ],
        ),
        const SizedBox(height: 12),
        _TeachingSkillCard(
          icon: Icons.translate_rounded,
          iconBg: cs.primaryFixed.withValues(alpha: 0.5),
          iconColor: cs.primary,
          title: 'French Language',
          level: 'Fluent',
          desc: 'Conversational, Pronunciation, Grammar',
          rating: '5.0',
        ),
        const SizedBox(height: 10),
        _TeachingSkillCard(
          icon: Icons.music_note_rounded,
          iconBg: const Color(0xFF71F8E4).withValues(alpha: 0.5), // secondary-fixed
          iconColor: cs.secondary,
          title: 'Acoustic Guitar',
          level: 'Beginner',
          desc: 'Chords, Fingerstyle, Rhythm basics',
          rating: '4.8',
        ),
      ],
    );
  }
}

class _TeachingSkillCard extends StatelessWidget {
  const _TeachingSkillCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.level,
    required this.desc,
    required this.rating,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String level;
  final String desc;
  final String rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        level,
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: cs.tertiaryContainer),
                const SizedBox(width: 4),
                Text(rating, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
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
            Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Skills I Want to Learn', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _WishChip(icon: Icons.palette_outlined, label: 'Figma & UI Design', isPrimary: true),
              _WishChip(icon: Icons.draw_outlined, label: 'Pottery'),
              _WishChip(icon: Icons.record_voice_over_outlined, label: 'Korean'),
              _WishChip(icon: Icons.surfing_outlined, label: 'Surfing'),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
                child: Icon(Icons.add_rounded, size: 18, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WishChip extends StatelessWidget {
  const _WishChip({required this.icon, required this.label, this.isPrimary = false});
  final IconData icon;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? cs.secondaryContainer.withValues(alpha: 0.4) : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isPrimary ? cs.onSecondaryContainer : cs.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPrimary ? cs.onSecondaryContainer : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Bookings Section
// ─────────────────────────────────────────────────────────────────────────────
class _MyBookingsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Bookings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
                Text('Scheduled peer-to-peer exchanges', style: theme.textTheme.bodySmall),
              ],
            ),
            GestureDetector(
              onTap: onToggleEmptyView,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryFixed.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  showEmptyView ? 'Show Normal' : 'Toggle View',
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Tabs
        if (!showEmptyView)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _TabButton(label: 'Upcoming (2)', isSelected: selectedTab == 0, onTap: () => onTabChanged(0))),
                Expanded(child: _TabButton(label: 'Completed (14)', isSelected: selectedTab == 1, onTap: () => onTabChanged(1))),
                Expanded(child: _TabButton(label: 'Cancelled (1)', isSelected: selectedTab == 2, onTap: () => onTabChanged(2))),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        if (showEmptyView)
          _EmptyView()
        else if (selectedTab == 0)
          const _UpcomingPanel()
        else if (selectedTab == 1)
          const _CompletedPanel()
        else
          const _CancelledPanel(),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.isSelected, required this.onTap});
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
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

class _UpcomingPanel extends StatelessWidget {
  const _UpcomingPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Column(
      children: [
        // Card 1
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 24, backgroundColor: cs.surfaceContainer, backgroundImage: const CachedNetworkImageProvider('https://i.pravatar.cc/150?img=47')),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(width: 12, height: 12, decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle, border: Border.all(color: cs.surfaceContainerLowest, width: 2))),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Figma Design Systems', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('with Maya Lin · 1:1 Video Session', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFFDDB8), borderRadius: BorderRadius.circular(100)), // tertiary-fixed
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFF2A1700)),
                        const SizedBox(width: 4),
                        Text('In 18 hours', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF2A1700), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text('Tomorrow, Oct 24 · 3:30 PM - 4:30 PM', style: theme.textTheme.labelMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Maya teaches: Figma Tokens', style: theme.textTheme.bodySmall),
                        Icon(Icons.sync_alt_rounded, size: 16, color: cs.primary),
                        Text('You teach: French Idioms', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.video_camera_front_rounded, size: 20),
                  label: const Text('Join Video Room'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(backgroundColor: cs.surfaceContainer, side: BorderSide.none),
                        onPressed: () {},
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: const Text('Reschedule'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(backgroundColor: cs.surfaceContainer, side: BorderSide.none),
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Card 2
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 24, backgroundColor: cs.surfaceContainer, backgroundImage: const CachedNetworkImageProvider('https://i.pravatar.cc/150?img=11')),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(width: 12, height: 12, decoration: BoxDecoration(color: cs.outlineVariant, shape: BoxShape.circle, border: Border.all(color: cs.surfaceContainerLowest, width: 2))),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spanish Conversation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('with Carlos R. · Intermediate', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(100)),
                    child: Text('In 4 days', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    Text('Monday, Oct 28 · 5:00 PM - 6:00 PM PST', style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(backgroundColor: cs.surfaceContainer, side: BorderSide.none),
                        onPressed: () {},
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('Details'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(backgroundColor: cs.surfaceContainer, side: BorderSide.none),
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletedPanel extends StatefulWidget {
  const _CompletedPanel();

  @override
  State<_CompletedPanel> createState() => _CompletedPanelState();
}

class _CompletedPanelState extends State<_CompletedPanel> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: cs.surfaceContainer, backgroundImage: const CachedNetworkImageProvider('https://i.pravatar.cc/150?img=5')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pottery Wheel Basics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('with Sarah Chen · Oct 18', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF4FDBC8).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(100)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF005048)),
                    const SizedBox(width: 4),
                    Text('Completed', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF005048), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('How was your swap with Sarah?', style: theme.textTheme.labelMedium),
                    Text('Tap to rate', style: theme.textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final isActive = i < _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.star_rounded,
                              size: 24,
                              color: isActive ? cs.tertiaryContainer : cs.outlineVariant,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('Rate Teacher'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledPanel extends StatelessWidget {
  const _CancelledPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: cs.errorContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: Icon(Icons.event_busy_rounded, size: 20, color: cs.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intro to Korean Verbs', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Cancelled by instructor · Mutual credit refunded', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: cs.primaryFixed, shape: BoxShape.circle)),
                Icon(Icons.auto_stories_rounded, size: 36, color: cs.primary),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome_rounded, size: 16, color: cs.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('No upcoming sessions', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Your schedule is clear! You have 6 swap credits ready to trade for new knowledge.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => context.go('/skills'),
              icon: const Icon(Icons.explore_rounded, size: 20),
              label: const Text('Discover Skills to Swap'),
            ),
          ),
        ],
      ),
    );
  }
}
