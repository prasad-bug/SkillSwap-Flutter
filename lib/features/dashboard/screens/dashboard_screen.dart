import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/skill_card.dart';
import '../../../core/widgets/skill_card_skeleton.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/category_theme_extension.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/booking.dart';
import '../providers/dashboard_providers.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchBar(),
                _CategoryChips(),
                _PopularSkillsSection(),
                _UpcomingSessionsSection(),
                _RecentChatsSection(),
                _OfferSkillBanner(),
                const SizedBox(height: AppConstants.spaceXXL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAppBar extends ConsumerWidget {
  const _DashboardAppBar({this.user});
  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.sync_alt_rounded, color: cs.onPrimary, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SkillSwap',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Home',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
          onPressed: () {},
        ),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              child: Text(
                user?.initials ?? '?',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.spaceMD,
          AppConstants.spaceMD, AppConstants.spaceMD, 0),
      child: GestureDetector(
        onTap: () => context.push('/skills'),
        child: Hero(
          tag: 'search_bar',
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    'Search skills, teachers...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  static const _categories = [
    ('Technology', Icons.computer_rounded),
    ('Music', Icons.music_note_rounded),
    ('Language', Icons.language_rounded),
    ('Art', Icons.palette_rounded),
    ('Fitness', Icons.fitness_center_rounded),
    ('Cooking', Icons.restaurant_rounded),
    ('Business', Icons.business_center_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final catExt = CategoryThemeExtension.of(context);
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceMD, vertical: AppConstants.spaceSM),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (label, icon) = _categories[i];
          final color = catExt.colorForCategory(label.toLowerCase());
          return ActionChip(
            avatar: Icon(icon, size: 16),
            label: Text(label),
            backgroundColor: color.withValues(alpha: 0.1),
            side: BorderSide(color: color.withValues(alpha: 0.2)),
            onPressed: () => context.push('/skills?category=${label.toLowerCase()}'),
          );
        },
      ),
    );
  }
}

class _PopularSkillsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(popularSkillsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16), // Padding for section separation
        skillsAsync.when(
          data: (skills) => SizedBox(
            height: 340, // Taller to fit redesigned card layout
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceMD),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none, // Allow soft shadow
              itemCount: skills.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (ctx, i) {
                final skill = skills[i];
                return SizedBox(
                  width: 300,
                  child: SkillCard(skill: skill),
                );
              },
            ),
          ),
          loading: () => SizedBox(
            height: 340,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, __) =>
                  const SizedBox(width: 300, child: SkillCardSkeleton()),
            ),
          ),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _UpcomingSessionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(upcomingBookingsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Upcoming Sessions',
          onSeeAll: () => context.go('/bookings'),
        ),
        bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceMD),
                child: Card(
                  elevation: 0,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spaceMD),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'No upcoming sessions.\nBook one now!',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceMD),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.take(3).length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _BookingTile(booking: bookings[i]),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final df = DateFormat('EEE, MMM d • h:mm a');

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.school_rounded, color: cs.onPrimaryContainer),
        ),
        title: Text(booking.skillTitle, style: theme.textTheme.titleSmall),
        subtitle: Text(df.format(booking.dateTime),
            style: theme.textTheme.bodySmall),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: booking.status == BookingStatus.confirmed
                ? cs.secondaryContainer.withValues(alpha: 0.4)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            booking.status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: booking.status == BookingStatus.confirmed
                  ? cs.onSecondaryContainer
                  : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => context.go('/bookings'),
      ),
    );
  }
}

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
        const _SectionHeader(
          title: 'Recent Chats',
          onSeeAll: null,
        ),
        threadsAsync.when(
          data: (threads) {
            if (threads.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
                child: Card(
                  elevation: 0,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spaceMD),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text('No chats yet. Message a skill owner!',
                            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
              child: Card(
                elevation: 0,
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: threads.take(3).length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                      itemBuilder: (ctx, i) {
                        final thread = threads[i];
                        final otherId = thread.otherParticipantId(currentUserId);
                        final otherUserAsync = ref.watch(userByIdProvider(otherId));
                        return otherUserAsync.when(
                          data: (other) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: other?.avatarUrl != null ? NetworkImage(other!.avatarUrl!) : null,
                              child: other?.avatarUrl == null
                                  ? Text(
                                      other?.initials ?? '?',
                                      style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
                                    )
                                  : null,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(other?.name ?? 'Unknown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  _formatTime(thread.lastMessageAt ?? DateTime.now()),
                                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    thread.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                if (thread.unreadCount > 0)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => context.push(
                              '/chats/${thread.id}',
                              extra: {'otherUserName': other?.name ?? '', 'otherUserId': otherId},
                            ),
                          ),
                          loading: () => const ListTile(title: LinearProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                    TextButton(
                      onPressed: () => context.go('/chats'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                      ),
                      child: const Text('Open Inbox'),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return DateFormat('h:mm a').format(time);
    }
    if (now.difference(time).inDays < 1) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(time);
  }
}

class _OfferSkillBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.spaceMD, AppConstants.spaceXL, AppConstants.spaceMD, 0),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spaceLG),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
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
                      color: cs.onPrimary.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teach 1 hour, earn 2 credits this week!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Zero fees. Pure community knowledge exchange.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {}, // Navigate to add skill form
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.onPrimary,
                foregroundColor: cs.primary,
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Offer Skill'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.spaceMD,
          AppConstants.spaceLG, AppConstants.spaceMD, AppConstants.spaceSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }
}
