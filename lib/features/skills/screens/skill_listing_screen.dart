import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/skill_card.dart';
import '../../../core/widgets/skill_card_skeleton.dart';
import '../../../core/widgets/empty_error_states.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/skill.dart';
import '../../../data/repositories/skill_repository.dart';
import '../providers/skill_providers.dart';

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
    // Apply initial category filter if given
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null) {
        final cat = SkillCategory.fromString(widget.initialCategory!);
        ref.read(skillFilterProvider.notifier).setCategory(cat);
      }
    });
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
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(skillFilterProvider);
    final notifier = ref.read(skillFilterProvider.notifier);
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Skills'),
        actions: [
          if (notifier.hasActiveFilters)
            TextButton(
              onPressed: () {
                notifier.clearFilters();
                _searchCtrl.clear();
              },
              child: const Text('Clear'),
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: notifier.hasActiveFilters,
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.spaceMD,
                AppConstants.spaceSM, AppConstants.spaceMD, 0),
            child: Hero(
              tag: 'search_bar',
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search skills, tags, teachers...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCtrl.clear();
                              notifier.setQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => notifier.setQuery(v),
                ),
              ),
            ),
          ),
          // Sort row
          _SortRow(filter: filter, notifier: notifier),
          // Active filters chips
          if (filter.category != null || filter.level != null ||
              filter.availability != null || filter.minRating > 0)
            _ActiveFilterChips(filter: filter, notifier: notifier),
          // Skills grid
          Expanded(
            child: skillsAsync.when(
              data: (skills) {
                if (skills.isEmpty) {
                  return EmptyState(
                    title: 'No skills found',
                    message: 'Try adjusting your filters or search term.',
                    icon: Icons.search_off_rounded,
                    action: () {
                      notifier.clearFilters();
                      _searchCtrl.clear();
                    },
                    actionLabel: 'Clear Filters',
                  );
                }
                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppConstants.spaceMD),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isWide ? 300 : 400,
                        childAspectRatio: isWide ? 0.7 : 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: skills.length,
                      itemBuilder: (ctx, i) {
                        final skill = skills[i];
                        return SkillCard(skill: skill);
                      },
                    );
                  },
                );
              },
              loading: () => const SkillListSkeleton(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(skillsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.filter, required this.notifier});
  final SkillFilter filter;
  final SkillFilterNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMD, vertical: AppConstants.spaceSM),
      child: Row(
        children: SkillSortBy.values.map((s) {
          final selected = filter.sortBy == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(s.label),
              selected: selected,
              onSelected: (_) => notifier.setSortBy(s),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips(
      {required this.filter, required this.notifier});
  final SkillFilter filter;
  final SkillFilterNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
      child: Row(
        children: [
          if (filter.category != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(filter.category!.label),
                onDeleted: () => notifier.setCategory(null),
              ),
            ),
          if (filter.level != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(filter.level!.label),
                onDeleted: () => notifier.setLevel(null),
              ),
            ),
          if (filter.availability != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(filter.availability!.label),
                onDeleted: () => notifier.setAvailability(null),
              ),
            ),
          if (filter.minRating > 0)
            Chip(
              label: Text('★ ${filter.minRating.toStringAsFixed(1)}+'),
              onDeleted: () => notifier.setMinRating(0),
            ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ────────────────────────────────────────────────────────
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Skills', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    setState(() => _local = const SkillFilter());
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(AppConstants.spaceMD),
              children: [
                // Category
                Text('Category', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: SkillCategory.values.map((c) {
                    final sel = _local.category == c;
                    return FilterChip(
                      label: Text(c.label),
                      selected: sel,
                      onSelected: (_) => setState(
                          () => _local = _local.copyWith(
                              category: sel ? null : c,
                              clearCategory: sel)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.spaceMD),
                // Level
                Text('Level', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: SkillLevel.values.map((l) {
                    final sel = _local.level == l;
                    return FilterChip(
                      label: Text(l.label),
                      selected: sel,
                      onSelected: (_) => setState(
                          () => _local = _local.copyWith(
                              level: sel ? null : l, clearLevel: sel)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.spaceMD),
                // Availability
                Text('Availability', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: AvailabilityStatus.values.map((a) {
                    final sel = _local.availability == a;
                    return FilterChip(
                      label: Text(a.label),
                      selected: sel,
                      onSelected: (_) => setState(
                          () => _local = _local.copyWith(
                              availability: sel ? null : a,
                              clearAvailability: sel)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.spaceMD),
                // Min rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Min Rating', style: theme.textTheme.titleSmall),
                    Text('★ ${_local.minRating.toStringAsFixed(1)}',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
                Slider(
                  value: _local.minRating,
                  min: 0, max: 5, divisions: 10,
                  onChanged: (v) =>
                      setState(() => _local = _local.copyWith(minRating: v)),
                ),
                const SizedBox(height: AppConstants.spaceLG),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMD),
            child: ElevatedButton(
              onPressed: () {
                ref.read(skillFilterProvider.notifier).setFilter(_local);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
