import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/skill_card.dart';
import '../../../core/widgets/skill_card_skeleton.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/booking.dart';
import '../providers/dashboard_providers.dart';

/// Dashboard / Home Screen exactly matching the approved Stitch HTML design.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          _DashboardAppBar(user: user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Greeting Banner & Search
                  _GreetingAndSearchBar(user: user),
                  const SizedBox(height: 24),

                  // 2. Upcoming Session Card
                  _UpcomingSessionSection(),
                  const SizedBox(height: 24),

                  // 3. Explore Categories
                  _ExploreCategoriesSection(),
                  const SizedBox(height: 24),

                  // 4. Popular Skills Carousel
                  _PopularSkillsSection(),
                  const SizedBox(height: 24),

                  // 5. Recent Chats Section
                  _RecentChatsSection(),
                  const SizedBox(height: 24),

                  // 6. Community Bonus Banner
                  _CommunityBonusBanner(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardAppBar extends ConsumerWidget {
  const _DashboardAppBar({this.user});
  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      backgroundColor: cs.surface.withValues(alpha: 0.9),
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
                'Home',
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
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Padding(
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
                backgroundImage: user?.avatarUrl != null
                    ? CachedNetworkImageProvider(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        user?.initials ?? '?',
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Greeting & Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingAndSearchBar extends StatelessWidget {
  const _GreetingAndSearchBar({this.user});
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final firstName = user?.name.split(' ').first ?? 'Alex';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Greeting Row + Swap Credits Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hey $firstName',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'What skill would you like to learn or swap today?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Skill Balance Chip matching Stitch HTML
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryFixed,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '3 Swap Credits',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onPrimaryFixedVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search Bar with search, mic, and filters icons
        GestureDetector(
          onTap: () => context.push('/skills'),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: cs.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search skills (e.g. Spanish, UI Design, Guitar)...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.mic_none_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Upcoming Session Section (Tactile Priority Alert)
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingSessionSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(upcomingBookingsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with animated pulsing indicator & View Calendar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _PulsingIndicator(color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Session',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/bookings'),
              child: Text(
                'View Calendar',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        bookingsAsync.when(
          data: (bookings) {
            final booking = bookings.isNotEmpty ? bookings.first : null;
            return _UpcomingSessionCard(booking: booking);
          },
          loading: () => const SkillCardSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _UpcomingSessionCard extends StatelessWidget {
  const _UpcomingSessionCard({this.booking});
  final Booking? booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title = booking?.skillTitle ?? 'Acoustic Guitar Basics';
    const teacherName = 'Elena Vance';
    const timeStr = 'Tomorrow, 4:00 PM';
    final durationStr = '${booking?.durationMins ?? 45}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                backgroundImage: const CachedNetworkImageProvider(
                  'https://i.pravatar.cc/150?img=5',
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
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            durationStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'with $teacherName',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Join Call & Reschedule buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connecting to video session...')),
                      );
                    },
                    icon: const Icon(Icons.videocam_rounded, size: 20),
                    label: const Text('Join Call'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/bookings'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: cs.surfaceContainerLow,
                    foregroundColor: cs.onSurface,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Reschedule'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget {
  const _PulsingIndicator({required this.color});
  final Color color;

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4 * _animation.value),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Explore Categories Section
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreCategoriesSection extends StatelessWidget {
  static const _categories = [
    ('Tech', Icons.terminal_rounded, 42, true),
    ('Music', Icons.music_note_rounded, 28, false),
    ('Language', Icons.translate_rounded, 35, false),
    ('Art', Icons.palette_rounded, 19, false),
    ('Fitness', Icons.fitness_center_rounded, 24, false),
    ('Cooking', Icons.restaurant_rounded, 16, false),
    ('Business', Icons.trending_up_rounded, 31, false),
  ];

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
            Text(
              'Explore Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            Text(
              'Swipe to browse',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: _categories.map((cat) {
              final (label, icon, count, isSelected) = cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: isSelected ? cs.primaryFixed : cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    onTap: () => context.push('/skills?category=${label.toLowerCase()}'),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? cs.primaryFixed
                              : cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected
                                ? cs.primary
                                : (label == 'Music' || label == 'Cooking'
                                    ? cs.tertiaryContainer
                                    : (label == 'Language' || label == 'Fitness'
                                        ? cs.secondary
                                        : (label == 'Art' ? cs.primary : cs.outline))),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected ? cs.onPrimaryFixed : cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($count)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? cs.onPrimaryFixed.withValues(alpha: 0.7)
                                  : cs.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Popular Skills Section
// ─────────────────────────────────────────────────────────────────────────────

class _PopularSkillsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(popularSkillsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Skills',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/skills'),
              child: Text(
                'See All',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        skillsAsync.when(
          data: (skills) => SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: skills.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (ctx, i) {
                return SkillCard(skill: skills[i]);
              },
            ),
          ),
          loading: () => SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => const SizedBox(
                width: 280,
                child: SkillCardSkeleton(),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Recent Chats Section
// ─────────────────────────────────────────────────────────────────────────────

class _RecentChatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(dashboardChatsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final currentUserId = userAsync.asData?.value?.id ?? '';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Chats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/chats'),
              child: Text(
                'Open Inbox',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: threadsAsync.when(
            data: (threads) {
              if (threads.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No chats yet. Message a skill teacher to start swapping!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: List.generate(threads.take(3).length, (idx) {
                  final thread = threads[idx];
                  final otherId = thread.otherParticipantId(currentUserId);
                  final otherUserAsync = ref.watch(userByIdProvider(otherId));
                  final isUnread = thread.unreadCount > 0;

                  return otherUserAsync.when(
                    data: (other) {
                      final name = other?.name ?? 'Teacher';
                      final timeStr = _formatChatTime(thread.lastMessageAt ?? DateTime.now());

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push(
                            '/chats/${thread.id}',
                            extra: {'otherUserName': name, 'otherUserId': otherId},
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                // Avatar with online dot
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: cs.primaryContainer,
                                      backgroundImage: other?.avatarUrl != null
                                          ? CachedNetworkImageProvider(other!.avatarUrl!)
                                          : null,
                                      child: other?.avatarUrl == null
                                          ? Text(
                                              other?.initials ?? '?',
                                              style: TextStyle(
                                                color: cs.onPrimaryContainer,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (idx == 0)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: cs.secondary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cs.surfaceContainerLowest,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Name, timestamp, preview
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            name,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: isUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: cs.onSurface,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            timeStr,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: isUnread ? cs.secondary : cs.outline,
                                              fontWeight: isUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        thread.lastMessage,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isUnread ? cs.onSurface : cs.onSurfaceVariant,
                                          fontWeight: isUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Unread indicator dot
                                if (isUnread) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              );
            },
            loading: () => const SizedBox(height: 120),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  String _formatChatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return DateFormat('h:mm a').format(dt);
    }
    final diff = now.difference(dt);
    if (diff.inDays <= 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Community Bonus Banner (Mutual Empowerment Banner)
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityBonusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient decorative circles
          Positioned(
            right: -24,
            bottom: -32,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned(
            right: 48,
            top: -24,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'COMMUNITY BONUS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.secondaryContainer,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Teach 1 hour, earn 2 credits this week!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Zero fees. Pure community knowledge exchange.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // "Offer Skill" button
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offer skill creation coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.surfaceContainerLowest,
                    foregroundColor: cs.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Offer Skill',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
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
