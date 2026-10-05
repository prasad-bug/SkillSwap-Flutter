import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/booking.dart';
import '../providers/booking_providers.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Booking> _bookingsForDay(List<Booking> all, DateTime day) {
    return all
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            b.dateTime.year == day.year &&
            b.dateTime.month == day.month &&
            b.dateTime.day == day.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bookingsAsync = ref.watch(userBookingsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              height: 32, width: 32,
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.sync_alt_rounded, color: cs.onPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SkillSwap', style: theme.textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold, height: 1.1)),
                Text('My Bookings', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Calendar'), Tab(text: 'List')],
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final now = DateTime.now();
          final upcoming = bookings
              .where((b) => b.dateTime.isAfter(now) && b.status != BookingStatus.cancelled)
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

          final past = bookings
              .where((b) => b.dateTime.isBefore(now) || b.status == BookingStatus.cancelled || b.status == BookingStatus.completed)
              .toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          final selectedDayBookings = _bookingsForDay(bookings, _selectedDay);

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Calendar Tab ───────────────────────────────────────────────
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TableCalendar
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
                          ),
                          child: TableCalendar<Booking>(
                            firstDay: DateTime.now().subtract(const Duration(days: 365)),
                            lastDay: DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                            eventLoader: (day) => _bookingsForDay(bookings, day),
                            onFormatChanged: (format) => setState(() => _calendarFormat = format),
                            onDaySelected: (selected, focused) {
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                              });
                            },
                            onPageChanged: (focused) => setState(() => _focusedDay = focused),
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: false,
                              selectedDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                              selectedTextStyle: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold),
                              todayDecoration: BoxDecoration(border: Border.all(color: cs.primary, width: 1.5), shape: BoxShape.circle),
                              todayTextStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                              markerDecoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle),
                              markersMaxCount: 3,
                              markerSize: 5,
                              markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonDecoration: BoxDecoration(
                                border: Border.all(color: cs.outline),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              formatButtonTextStyle: TextStyle(color: cs.onSurface, fontSize: 12),
                              titleCentered: true,
                              titleTextStyle: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: cs.onSurface),
                              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: cs.onSurface),
                            ),
                          ),
                        ),

                        // Legend
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Row(
                            children: [
                              _Dot(color: cs.secondary),
                              const SizedBox(width: 4),
                              Text('Booking on this day', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                              const Spacer(),
                              Text(
                                DateFormat('MMMM d, yyyy').format(_selectedDay),
                                style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        // Selected day bookings header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Icon(Icons.event_note_rounded, size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Text(
                                selectedDayBookings.isEmpty
                                    ? 'No bookings on ${DateFormat('MMM d').format(_selectedDay)}'
                                    : '${selectedDayBookings.length} booking${selectedDayBookings.length > 1 ? 's' : ''} on ${DateFormat('MMM d').format(_selectedDay)}',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Booking cards for selected day
                  if (selectedDayBookings.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 48, color: cs.outlineVariant),
                            const SizedBox(height: 12),
                            Text('No sessions on this day', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/skills'),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Book a Session'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            if (i < selectedDayBookings.length - 1) {
                              // Add spacing between items
                            }
                            final b = selectedDayBookings[i];
                            final isLearner = b.learnerId == (currentUser?.id ?? '');
                            final otherUserId = isLearner ? b.teacherId : b.learnerId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BookingCard(
                                booking: b,
                                isLearner: isLearner,
                                otherUserId: otherUserId,
                                isUpcoming: b.dateTime.isAfter(DateTime.now()),
                              ),
                            );
                          },
                          childCount: selectedDayBookings.length,
                        ),
                      ),
                    ),
                ],
              ),

              // ── List Tab ───────────────────────────────────────────────────
              _ListTab(
                upcoming: upcoming,
                past: past,
                currentUserId: currentUser?.id ?? '',
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List Tab (Upcoming / Past sections)
// ─────────────────────────────────────────────────────────────────────────────
class _ListTab extends ConsumerWidget {
  const _ListTab({required this.upcoming, required this.past, required this.currentUserId});
  final List<Booking> upcoming;
  final List<Booking> past;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;


    if (upcoming.isEmpty && past.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.4), shape: BoxShape.circle),
              child: Icon(Icons.calendar_today_rounded, size: 40, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text('No bookings yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Explore skills and book a session!', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/skills'),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Skills'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (upcoming.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.upcoming_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('Upcoming', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(100)),
                    child: Text('${upcoming.length}', style: theme.textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final b = upcoming[i];
                  final isLearner = b.learnerId == currentUserId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(booking: b, isLearner: isLearner, otherUserId: isLearner ? b.teacherId : b.learnerId, isUpcoming: true),
                  );
                },
                childCount: upcoming.length,
              ),
            ),
          ),
        ],
        if (past.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Past', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final b = past[i];
                  final isLearner = b.learnerId == currentUserId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(booking: b, isLearner: isLearner, otherUserId: isLearner ? b.teacherId : b.learnerId, isUpcoming: false),
                  );
                },
                childCount: past.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Booking Card
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends ConsumerStatefulWidget {
  const _BookingCard({required this.booking, required this.isLearner, required this.otherUserId, required this.isUpcoming});
  final Booking booking;
  final bool isLearner;
  final String otherUserId;
  final bool isUpcoming;

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isCancelling = false;

  Color _statusColor(BuildContext context, BookingStatus s) {
    final cs = Theme.of(context).colorScheme;
    switch (s) {
      case BookingStatus.confirmed: return Colors.green;
      case BookingStatus.pending: return cs.secondary;
      case BookingStatus.completed: return cs.primary;
      case BookingStatus.cancelled: return cs.error;
    }
  }

  IconData _statusIcon(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed: return Icons.check_circle_rounded;
      case BookingStatus.pending: return Icons.hourglass_top_rounded;
      case BookingStatus.completed: return Icons.star_rounded;
      case BookingStatus.cancelled: return Icons.cancel_rounded;
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, Keep It')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(widget.booking.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final b = widget.booking;
    final statusColor = _statusColor(context, b.status);
    final statusIcon = _statusIcon(b.status);

    return FutureBuilder(
      future: ref.read(userRepositoryProvider).getUserById(widget.otherUserId),
      builder: (context, snap) {
        final otherName = snap.data?.name ?? (snap.connectionState == ConnectionState.waiting ? 'Loading...' : 'Unknown');

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: role + status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.isLearner ? cs.primaryContainer : cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(widget.isLearner ? 'Learning' : 'Teaching',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.isLearner ? cs.onPrimaryContainer : cs.onSecondaryContainer,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(b.status.label, style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(b.skillTitle.isNotEmpty ? b.skillTitle : 'Skill Session',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.person_rounded, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(widget.isLearner ? 'Teacher: $otherName' : 'Student: $otherName',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(DateFormat('EEE, MMM d • h:mm a').format(b.dateTime),
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(100)),
                    child: Text('${b.durationMins} min', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ]),
                if (b.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                    child: Text(b.notes, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
                if (widget.isUpcoming && b.status != BookingStatus.cancelled) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _cancelBooking,
                        icon: _isCancelling
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(foregroundColor: cs.error, side: BorderSide(color: cs.error.withValues(alpha: 0.5)), visualDensity: VisualDensity.compact),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.push('/chats'),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text('Message'),
                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                  ]),
                ],
                if (!widget.isUpcoming && b.status == BookingStatus.completed) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/rating/${b.id}', extra: {
                        'toUserId': widget.otherUserId, 'toUserName': otherName,
                        'skillId': b.skillId, 'skillTitle': b.skillTitle,
                      }),
                      icon: const Icon(Icons.star_rounded, size: 16),
                      label: const Text('Rate This Session'),
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
