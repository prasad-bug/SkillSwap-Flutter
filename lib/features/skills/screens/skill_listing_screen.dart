import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/category_theme_extension.dart';
import '../../../data/models/skill.dart';
import '../../../data/repositories/skill_repository.dart';
import '../providers/skill_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Explore Screen (Skill Listing)  –  matches Stitch HTML design
// ─────────────────────────────────────────────────────────────────────────────

class SkillListingScreen extends ConsumerStatefulWidget {
  const SkillListingScreen({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  ConsumerState<SkillListingScreen> createState() =>
      _SkillListingScreenState();
}

class _SkillListingScreenState extends ConsumerState<SkillListingScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null) {
        final cat = SkillCategory.fromString(widget.initialCategory!);
        ref.read(skillFilterProvider.notifier).setCategory(cat);
      }
    });
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filter = ref.watch(skillFilterProvider);
    final notifier = ref.read(skillFilterProvider.notifier);
    final skillsAsync = ref.watch(skillsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;

    final activeFilterCount = [
      filter.category != null,
      filter.level != null,
      filter.availability != null,
      filter.minRating > 0,
    ].where((b) => b).length;

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: cs.surface.withValues(alpha: 0.9),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            title: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sync_alt_rounded,
                      color: cs.onPrimary, size: 20),
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
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Explore',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: cs.onSurfaceVariant),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: currentUser?.avatarUrl != null
                        ? CachedNetworkImageProvider(currentUser!.avatarUrl!)
                        : null,
                    child: currentUser?.avatarUrl == null
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
          ),
        ],
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.95),
              surfaceTintColor: Colors.transparent,
              pinned: true,
              floating: false,
              elevation: 0,
              automaticallyImplyLeading: false,
              expandedHeight: 0,
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(108),
                child: _SearchAndChipsHeader(
                  controller: _searchCtrl,
                  filter: filter,
                  notifier: notifier,
                  activeFilterCount: activeFilterCount,
                  onOpenFilters: _openFilterSheet,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: skillsAsync.when(
                loading: () => const SliverToBoxAdapter(child: _SkeletonFeed()),
                error: (e, _) => SliverToBoxAdapter(
                  child: _ExploreEmptyState(
                    title: 'Something went wrong',
                    subtitle: e.toString(),
                    onReset: () {
                      notifier.clearFilters();
                      _searchCtrl.clear();
                    },
                  ),
                ),
                data: (skills) {
                  if (skills.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _ExploreEmptyState(
                        title: 'No skills match filters',
                        subtitle:
                            "We couldn't find matches for your active tags. Try easing your filters.",
                        onReset: () {
                          notifier.clearFilters();
                          _searchCtrl.clear();
                        },
                      ),
                    );
                  }
                  return SliverList.separated(
                    itemCount: skills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) => _ExploreSkillCard(skill: skills[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Search + Filter Chips Header
// ─────────────────────────────────────────────────────────────────────────────

class _SearchAndChipsHeader extends ConsumerWidget {
  const _SearchAndChipsHeader({
    required this.controller,
    required this.filter,
    required this.notifier,
    required this.activeFilterCount,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final SkillFilter filter;
  final SkillFilterNotifier notifier;
  final int activeFilterCount;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Icon(Icons.search_rounded,
                            color: cs.primary, size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: notifier.setQuery,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search by skill or user...',
                            hintStyle: theme.textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      if (controller.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: cs.onSurfaceVariant, size: 18),
                          onPressed: () {
                            controller.clear();
                            notifier.setQuery('');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onOpenFilters,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
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
                      Icon(Icons.tune_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 6),
                      Text('Filters',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: cs.primary)),
                      if (activeFilterCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '$activeFilterCount',
                              style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChipPill(
                  label: filter.level?.label ?? 'All Levels',
                  isActive: filter.level != null,
                  trailingIcon: Icons.expand_more_rounded,
                  onTap: onOpenFilters,
                ),
                const SizedBox(width: 8),
                if (filter.availability != null)
                  _ActiveFilterChipPill(
                    color: cs.secondary,
                    label: filter.availability!.label,
                    onRemove: () => notifier.setAvailability(null),
                  )
                else
                  _FilterChipPill(
                    label: 'Availability',
                    isActive: false,
                    onTap: onOpenFilters,
                  ),
                const SizedBox(width: 8),
                _FilterChipPill(
                  label: filter.minRating > 0
                      ? 'Top Rated ${filter.minRating.toStringAsFixed(1)}+'
                      : 'Top Rated 4.5+',
                  isActive: filter.minRating > 0,
                  leadingWidget: filter.minRating > 0
                      ? Icon(Icons.star_rounded,
                          size: 14, color: cs.tertiaryContainer)
                      : null,
                  onTap: onOpenFilters,
                ),
                if (filter.category != null) ...[
                  const SizedBox(width: 8),
                  _ActiveFilterChipPill(
                    color: cs.primary,
                    label: filter.category!.label,
                    onRemove: () => notifier.setCategory(null),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.isActive,
    this.onTap,
    this.trailingIcon,
    this.leadingWidget,
  });
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
  final Widget? leadingWidget;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryFixed : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingWidget != null) ...[
              leadingWidget!,
              const SizedBox(width: 4),
            ],
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isActive ? cs.onPrimaryFixed : cs.onSurfaceVariant,
                )),
            if (trailingIcon != null) ...[
              const SizedBox(width: 2),
              Icon(trailingIcon,
                  size: 16,
                  color: isActive ? cs.onPrimaryFixed : cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChipPill extends StatelessWidget {
  const _ActiveFilterChipPill({
    required this.color,
    required this.label,
    required this.onRemove,
  });
  final Color color;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryFixed,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onPrimaryFixed)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 14, color: cs.onPrimaryFixed),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Explore Skill Card
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreSkillCard extends ConsumerWidget {
  const _ExploreSkillCard({required this.skill});
  final Skill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ownerAsync = ref.watch(skillOwnerProvider(skill.ownerId));
    final owner = ownerAsync.asData?.value;

    final isLimited = skill.availability == AvailabilityStatus.limited;
    final isUnavailable = skill.availability == AvailabilityStatus.unavailable;
    final catIcon = CategoryThemeExtension.iconForCategory(skill.category.name);

    return GestureDetector(
      onTap: () => context.push('/skills/${skill.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isUnavailable
              ? cs.surfaceContainerLowest.withValues(alpha: 0.85)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Avatar + name + availability pill
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: owner?.avatarUrl != null
                                  ? CachedNetworkImageProvider(owner!.avatarUrl!)
                                  : null,
                              child: owner?.avatarUrl == null
                                  ? Text(
                                      owner?.initials ?? '?',
                                      style: TextStyle(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isUnavailable
                                      ? cs.outline
                                      : isLimited
                                          ? cs.tertiaryContainer
                                          : cs.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: cs.surfaceContainerLowest,
                                      width: 2),
                                ),
                              ),
                            ),
                          ],
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
                                      owner?.name ?? '...',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (owner != null &&
                                      owner.avgRating >= 4.5) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.verified_rounded,
                                        size: 16, color: cs.primary),
                                  ],
                                ],
                              ),
                              Text(
                                owner?.bio.isNotEmpty == true
                                    ? owner!.bio
                                    : skill.category.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AvailabilityPill(
                      availability: skill.availability, cs: cs, theme: theme),
                ],
              ),

              // Row 2: Title + description
              const SizedBox(height: 12),
              Text(
                skill.title,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    height: 1.25),
              ),
              const SizedBox(height: 4),
              Text(
                skill.description,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Row 3: Bilateral Swap Matrix
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: isUnavailable
                                    ? cs.surfaceContainerHigh
                                    : cs.primaryFixed,
                                borderRadius: BorderRadius.circular(6)),
                            child: Icon(catIcon,
                                size: 14,
                                color: isUnavailable
                                    ? cs.onSurfaceVariant
                                    : cs.onPrimaryFixed),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OFFERING',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: isUnavailable
                                          ? cs.onSurfaceVariant
                                          : cs.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                      letterSpacing: 0.8),
                                ),
                                Text(
                                  skill.title.length > 22
                                      ? '${skill.title.substring(0, 22)}…'
                                      : skill.title,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.swap_horiz_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'SEEKING',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: isUnavailable
                                          ? cs.onSurfaceVariant
                                          : cs.secondary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                      letterSpacing: 0.8),
                                ),
                                Text(
                                  owner?.wantedSkills.isNotEmpty == true
                                      ? owner!.wantedSkills.first
                                      : 'Any skill match',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: isUnavailable
                                    ? cs.surfaceContainerHigh
                                    : const Color(0xFF71F8E4)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6)),
                            child: Icon(Icons.search_rounded,
                                size: 14, color: cs.onSecondaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Row 4: Footer
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14, color: cs.tertiaryContainer),
                        const SizedBox(width: 3),
                        Text(skill.avgRating.toStringAsFixed(1),
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface)),
                        Text(' (${skill.ratingCount})',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(skill.category.label,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(skill.level.label,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isUnavailable
                          ? null
                          : () => context.push('/skills/${skill.id}'),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: isUnavailable
                                ? cs.surfaceContainerHigh
                                : cs.primaryFixed,
                            shape: BoxShape.circle),
                        child: Icon(Icons.swap_calls_rounded,
                            size: 20,
                            color: isUnavailable
                                ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                                : cs.onPrimaryFixed),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill(
      {required this.availability, required this.cs, required this.theme});
  final AvailabilityStatus availability;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final (bgColor, dotColor, label) = switch (availability) {
      AvailabilityStatus.available => (
          const Color(0xFF71F8E4).withValues(alpha: 0.5),
          cs.secondary,
          'Available',
        ),
      AvailabilityStatus.limited => (
          const Color(0xFFFFDDB8).withValues(alpha: 0.7),
          cs.tertiary,
          'Limited',
        ),
      AvailabilityStatus.unavailable => (
          cs.surfaceContainer,
          cs.outline,
          'Unavailable',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: availability == AvailabilityStatus.unavailable
                      ? cs.onSurfaceVariant
                      : cs.onSurface,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreEmptyState extends StatelessWidget {
  const _ExploreEmptyState(
      {required this.title, required this.subtitle, required this.onReset});
  final String title;
  final String subtitle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
                color: cs.surfaceContainer, shape: BoxShape.circle),
            child: Icon(Icons.filter_alt_off_rounded,
                size: 48, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: cs.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            height: 48,
            child: FilledButton(
              onPressed: onReset,
              style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Reset All Filters',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onPrimary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loading Feed
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonFeed extends StatelessWidget {
  const _SkeletonFeed();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLow,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 110, height: 14, color: Colors.white),
                        const SizedBox(height: 6),
                        Container(width: 80, height: 10, color: Colors.white),
                      ],
                    ),
                    const Spacer(),
                    Container(
                        width: 70,
                        height: 24,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100))),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                    width: double.infinity, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 220, height: 11, color: Colors.white),
                const SizedBox(height: 12),
                Container(
                    height: 64,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                        width: 56,
                        height: 20,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(width: 8),
                    Container(
                        width: 48,
                        height: 20,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6))),
                    const Spacer(),
                    Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Filter Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SkillFilter _local;

  @override
  void initState() {
    super.initState();
    _local = ref.read(skillFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Text('Filter Skill Swaps',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // Categories
                  _SheetSection(
                    label: 'Categories',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SkillCategory.values.map((c) {
                        final sel = _local.category == c;
                        return _SheetChip(
                          label: c.label,
                          icon:
                              CategoryThemeExtension.iconForCategory(c.name),
                          isSelected: sel,
                          onTap: () => setState(() => _local = _local.copyWith(
                              category: sel ? null : c, clearCategory: sel)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Experience Level
                  _SheetSection(
                    label: 'Experience Level',
                    child: Row(
                      children: SkillLevel.values.map((l) {
                        final sel = _local.level == l;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _local =
                                  _local.copyWith(
                                      level: sel ? null : l,
                                      clearLevel: sel)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                    color: sel
                                        ? cs.primaryFixed
                                        : cs.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Text(l.label,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: sel
                                                    ? cs.onPrimaryFixed
                                                    : cs.onSurface),
                                        textAlign: TextAlign.center),
                                    Text(
                                        l == SkillLevel.beginner
                                            ? 'Foundations'
                                            : l == SkillLevel.intermediate
                                                ? 'Hands-on'
                                                : 'Mastery',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: sel
                                                    ? cs.onPrimaryFixed
                                                        .withValues(alpha: 0.75)
                                                    : cs.onSurfaceVariant,
                                                fontSize: 10),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Availability
                  _SheetSection(
                    label: 'Member Availability',
                    child: Column(
                      children: AvailabilityStatus.values
                          .where(
                              (a) => a != AvailabilityStatus.unavailable)
                          .map((a) {
                        final sel = _local.availability == a;
                        final dotColor = a == AvailabilityStatus.available
                            ? cs.secondary
                            : cs.tertiary;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _local =
                                _local.copyWith(
                                    availability: sel ? null : a,
                                    clearAvailability: sel)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                  color: cs.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                          color: dotColor,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(a.label,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: cs.onSurface)),
                                  ),
                                  Checkbox(
                                    value: sel,
                                    activeColor: cs.secondary,
                                    onChanged: (_) => setState(() => _local =
                                        _local.copyWith(
                                            availability: sel ? null : a,
                                            clearAvailability: sel)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Min Rating
                  _SheetSection(
                    label: 'Minimum Peer Rating',
                    headerTrailing: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: cs.tertiaryContainer),
                        const SizedBox(width: 2),
                        Text(
                          '${_local.minRating.toStringAsFixed(1)}+',
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: cs.primary,
                            thumbColor: cs.primary,
                            inactiveTrackColor: cs.surfaceContainerHigh,
                            overlayColor:
                                cs.primary.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: _local.minRating.clamp(4.0, 5.0),
                            min: 4.0,
                            max: 5.0,
                            divisions: 10,
                            onChanged: (v) => setState(
                                () => _local = _local.copyWith(minRating: v)),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: ['4.0', '4.5', '5.0']
                                .map((l) => Text(l,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                            color: cs.onSurfaceVariant)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _local = const SkillFilter());
                        ref
                            .read(skillFilterProvider.notifier)
                            .clearFilters();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text('Reset',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: cs.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(skillFilterProvider.notifier)
                              .setFilter(_local);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.arrow_forward_rounded,
                            size: 18),
                        label: Text('Apply Filters',
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection(
      {required this.label, required this.child, this.headerTrailing});
  final String label;
  final Widget child;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            if (headerTrailing != null) ...[
              const Spacer(),
              headerTrailing!,
            ],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      this.icon});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: isSelected ? cs.onPrimary : cs.onSurface),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
