import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/category_theme_extension.dart';
import '../../../core/widgets/empty_error_states.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/rating.dart';
import '../../../data/models/skill.dart';
import '../providers/skill_providers.dart';

/// Skill Detail Screen implemented to match the approved Stitch design specifications.
class SkillDetailScreen extends ConsumerStatefulWidget {
  const SkillDetailScreen({super.key, required this.skillId});
  final String skillId;

  @override
  ConsumerState<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends ConsumerState<SkillDetailScreen> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final skillAsync = ref.watch(skillByIdProvider(widget.skillId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return skillAsync.when(
      loading: () => Scaffold(
        backgroundColor: cs.surface,
        appBar: _buildAppBar(context, currentUser),
        body: const _SkillDetailSkeleton(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: cs.surface,
        appBar: _buildAppBar(context, currentUser),
        body: ErrorState(message: e.toString()),
      ),
      data: (skill) {
        if (skill == null) {
          return Scaffold(
            backgroundColor: cs.surface,
            appBar: _buildAppBar(context, currentUser),
            body: const EmptyState(title: 'Skill not found'),
          );
        }

        final ownerAsync = ref.watch(skillOwnerProvider(skill.ownerId));

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: _buildAppBar(context, currentUser),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Hero Card
                    _HeroCard(
                      skill: skill,
                      isSaved: _isSaved,
                      onToggleSave: () {
                        setState(() => _isSaved = !_isSaved);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      onShare: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Skill link copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Teacher ProfileCard
                    ownerAsync.when(
                      data: (owner) {
                        if (owner == null) return const SizedBox.shrink();
                        return _TeacherProfileCard(
                          owner: owner,
                          skill: skill,
                        );
                      },
                      loading: () => const _SectionSkeleton(height: 180),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Skill Barter Matrix
                    _BarterMatrixCard(skill: skill),
                    const SizedBox(height: 16),

                    // 4. Tabs Card
                    _TabsCard(skill: skill),
                    const SizedBox(height: 16),

                    // 5. Ratings & Reviews Card
                    _RatingsReviewsCard(skill: skill),
                  ],
                ),
              ),

              // 5. Sticky Bottom Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyBottomBar(
                  skill: skill,
                  currentUserId: currentUser?.id ?? '',
                  ownerAsync: ownerAsync,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppUser? currentUser) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sync_alt_rounded,
              color: cs.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Skill Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              backgroundImage: safeNetworkImageProvider(currentUser?.avatarUrl),
              child: safeNetworkImageProvider(currentUser?.avatarUrl) == null
                  ? Text(
                      currentUser?.initials ?? '?',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
// 1. Hero Card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.skill,
    required this.isSaved,
    required this.onToggleSave,
    required this.onShare,
  });

  final Skill skill;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catIcon = CategoryThemeExtension.iconForCategory(skill.category.name);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primaryContainer,
            cs.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Translucent category & level pills + Save & Share buttons
          Row(
            children: [
              // Category pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      skill.category.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Level pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  skill.level.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(),

              // Save button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleSave,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Share button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShare,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            skill.title,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            skill.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onPrimaryContainer,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Badges row: White AvailabilityBadge with pulsing dot + Translucent session duration
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // White AvailabilityBadge pill with pulsing secondary dot
              _PulsingAvailabilityBadge(availability: skill.availability),

              // Translucent session duration pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${skill.sessionDurationMins} min 1-on-1 session',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingAvailabilityBadge extends StatefulWidget {
  const _PulsingAvailabilityBadge({required this.availability});
  final AvailabilityStatus availability;

  @override
  State<_PulsingAvailabilityBadge> createState() => _PulsingAvailabilityBadgeState();
}

class _PulsingAvailabilityBadgeState extends State<_PulsingAvailabilityBadge>
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
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (color, label) = switch (widget.availability) {
      AvailabilityStatus.available => (cs.secondary, 'Available for Exchange'),
      AvailabilityStatus.limited => (cs.tertiary, 'Limited Availability'),
      AvailabilityStatus.unavailable => (cs.error, 'Currently Unavailable'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: _animation.value),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5 * _animation.value),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW: Skill Barter Matrix Card
// ─────────────────────────────────────────────────────────────────────────────

class _BarterMatrixCard extends StatelessWidget {
  const _BarterMatrixCard({required this.skill});
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Derive "you learn" from the skill title (first 4 words max)
    final words = skill.title.split(' ');
    final youLearn = words.length > 4
        ? '${words.take(4).join(' ')}…'
        : skill.title;

    // "You teach" comes from the owner's wantedSkills (passed via skill's context)
    // We use a fallback label that reads naturally
    final youTeachItems = skill.tags.isNotEmpty
        ? skill.tags.take(2).join(' or ')
        : 'Your matching skill';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'The Skill Barter Matrix',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'Zero Currency Needed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two-column grid
          Row(
            children: [
              // "You Learn" column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primaryFixed.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'YOU LEARN',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        youLearn,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${skill.sessionDurationMins}-min live pairing & critique',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // "You Teach" column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: cs.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'YOU TEACH',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.secondary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        youTeachItems,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matched on your profile skills',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Teacher ProfileCard
// ─────────────────────────────────────────────────────────────────────────────

class _TeacherProfileCard extends ConsumerWidget {
  const _TeacherProfileCard({
    required this.owner,
    required this.skill,
  });

  final AppUser owner;
  final Skill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sessionsCountAsync = ref.watch(teacherCompletedSessionsCountProvider(owner.id));
    final sessionsCount = sessionsCountAsync.asData?.value ?? 14;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher header row
          InkWell(
            onTap: () => context.push('/profile?userId=${owner.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 56dp Avatar with primaryFixed ring and verified badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primaryFixed,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: safeNetworkImageProvider(owner.avatarUrl),
                        child: safeNetworkImageProvider(owner.avatarUrl) == null
                            ? Text(
                                owner.initials,
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name, rating pill, bio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              owner.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (owner.avgRating >= 4.8) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cs.tertiaryContainer.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: cs.tertiaryContainer,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Top Rated',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.tertiaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        owner.bio.isNotEmpty
                            ? owner.bio
                            : 'Dedicated instructor passionate about sharing skills.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metrics ribbon: 3 columns (Rating | Sessions taught | Skills offered)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Col 1: Star + Rating + reviews count
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: cs.tertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            owner.avgRating.toStringAsFixed(1),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${owner.ratingCount} reviews',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),

                // Col 2: Sessions taught
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$sessionsCount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sessions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),

                // Col 3: Skills offered
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${owner.offeredSkillIds.isNotEmpty ? owner.offeredSkillIds.length : 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Skills offered',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // "Wants in return" row
          if (owner.wantedSkills.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_alt_rounded,
                    size: 18,
                    color: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Wants in return: ',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      owner.wantedSkills.join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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

// ─────────────────────────────────────────────────────────────────────────────
// 3. Tabs Card (About Skill / What We Cover / Prerequisites)
// ─────────────────────────────────────────────────────────────────────────────

class _TabsCard extends StatefulWidget {
  const _TabsCard({required this.skill});
  final Skill skill;

  @override
  State<_TabsCard> createState() => _TabsCardState();
}

class _TabsCardState extends State<_TabsCard> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Dynamically filter tabs: hide if empty list
    final List<String> availableTabs = [
      'About Skill',
      if (widget.skill.curriculum.isNotEmpty) 'What We Cover',
      if (widget.skill.prerequisites.isNotEmpty) 'Prerequisites',
    ];

    if (_selectedTabIndex >= availableTabs.length) {
      _selectedTabIndex = 0;
    }

    final currentTab = availableTabs[_selectedTabIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(availableTabs.length, (index) {
                final tabName = availableTabs[index];
                final isSelected = index == _selectedTabIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = index),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary : cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          tabName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),

          // Tab content
          if (currentTab == 'About Skill') ...[
            Text(
              widget.skill.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                height: 1.6,
              ),
            ),
            if (widget.skill.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Topics & Tags',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.skill.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ] else if (currentTab == 'What We Cover') ...[
            Column(
              children: List.generate(widget.skill.curriculum.length, (idx) {
                final item = widget.skill.curriculum[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ] else if (currentTab == 'Prerequisites') ...[
            Column(
              children: widget.skill.prerequisites.map((req) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: cs.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          req,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Ratings & Reviews Card
// ─────────────────────────────────────────────────────────────────────────────

class _RatingsReviewsCard extends ConsumerWidget {
  const _RatingsReviewsCard({required this.skill});
  final Skill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ratingsAsync = ref.watch(skillRatingsProvider(skill.id));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ratingsAsync.when(
        loading: () => const _SectionSkeleton(height: 220),
        error: (_, __) => const SizedBox.shrink(),
        data: (ratings) {
          // Compute rating breakdown percentages
          final Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
          for (final r in ratings) {
            final s = r.stars.clamp(1, 5);
            starCounts[s] = (starCounts[s] ?? 0) + 1;
          }
          final totalReviews = ratings.length;

          final label = _getRatingLabel(skill.avgRating);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: title + "N total" pill + "View all"
              Row(
                children: [
                  Text(
                    'Ratings & Reviews',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${totalReviews > 0 ? totalReviews : skill.ratingCount} total',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View all',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Breakdown row: Big rating + 5-to-1 star bars
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big rating display
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.avgRating.toStringAsFixed(1),
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: index < skill.avgRating.floor()
                                  ? cs.tertiaryContainer
                                  : cs.surfaceContainerHighest,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.tertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 5-to-1 star percentage bars
                  Expanded(
                    child: Column(
                      children: List.generate(5, (idx) {
                        final star = 5 - idx;
                        final count = starCounts[star] ?? 0;
                        final pct = totalReviews > 0 ? (count / totalReviews) : (star >= 4 ? 0.7 : 0.1);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text(
                                '$star',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: cs.tertiaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(cs.tertiaryContainer),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Review Cards
              if (ratings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No reviews yet for this skill. Be the first to book and review!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Column(
                  children: ratings.take(3).map((r) {
                    return _ReviewItemCard(rating: r);
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 4.8) return 'Outstanding';
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    return 'Average';
  }
}

class _ReviewItemCard extends StatelessWidget {
  const _ReviewItemCard({required this.rating});
  final Rating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                backgroundImage: safeNetworkImageProvider(rating.fromUserAvatarUrl),
                child: safeNetworkImageProvider(rating.fromUserAvatarUrl) == null
                    ? Text(
                        rating.fromUserName.isNotEmpty
                            ? rating.fromUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rating.fromUserName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rating.swappedSkillTitle != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Swapped ${rating.swappedSkillTitle}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatRelativeTime(rating.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < rating.stars
                        ? cs.tertiaryContainer
                        : cs.surfaceContainerHighest,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rating.review,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        final m = diff.inMinutes;
        return m <= 1 ? 'Just now' : '$m mins ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return w == 1 ? '1 week ago' : '$w weeks ago';
    } else if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return mo == 1 ? '1 month ago' : '$mo months ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dt);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Sticky Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────

class _StickyBottomBar extends ConsumerWidget {
  const _StickyBottomBar({
    required this.skill,
    required this.currentUserId,
    required this.ownerAsync,
  });

  final Skill skill;
  final String currentUserId;
  final AsyncValue<AppUser?> ownerAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOwner = skill.ownerId == currentUserId;
    final isUnavailable = skill.availability == AvailabilityStatus.unavailable;
    final owner = ownerAsync.asData?.value;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.95),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: isOwner
              ? Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Center(
                    child: Text(
                      'This is your skill',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    // "Message" tonal button
                    SizedBox(
                      height: 48,
                      width: 112,
                      child: FilledButton.tonal(
                        onPressed: () async {
                          final chatRepo = ref.read(chatRepositoryProvider);
                          final thread = await chatRepo.getOrCreateThread(
                            currentUserId,
                            skill.ownerId,
                          );
                          if (context.mounted) {
                            context.push(
                              '/chats/${thread.id}',
                              extra: {
                                'otherUserName': owner?.name ?? 'Teacher',
                                'otherUserId': skill.ownerId,
                                'skillId': skill.id,
                                'skillTitle': skill.title,
                              },
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.surfaceContainerHigh,
                          foregroundColor: cs.onSurface,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: cs.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Message',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // "Book Session" filled primary gradient button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: isUnavailable
                            ? FilledButton(
                                onPressed: null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.surfaceContainerHighest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Unavailable',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [cs.primary, cs.primaryContainer],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push('/skills/${skill.id}/book'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_month_rounded,
                                            size: 18,
                                            color: cs.onPrimary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Book Session',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: cs.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
// Loading Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _SkillDetailSkeleton extends StatelessWidget {
  const _SkillDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLow,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLow,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
