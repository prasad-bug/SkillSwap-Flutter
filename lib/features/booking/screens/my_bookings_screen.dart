import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _completeBooking(String bookingId) async {
    try {
      await ref.read(bookingRepositoryProvider).completeBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session marked as completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing session: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingRepositoryProvider).cancelBooking(bookingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  List<Booking> _filterBookings(List<Booking> bookings, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return bookings.where((b) => b.status == BookingStatus.confirmed).toList();
      case 2:
        return bookings.where((b) => b.status == BookingStatus.completed).toList();
      case 3:
        return bookings.where((b) => b.status == BookingStatus.cancelled).toList();
      default:
        return bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingsAsync = ref.watch(userBookingsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: bookingsAsync.when(
        data: (allBookings) {
          final filtered = _filterBookings(allBookings, _tabController.index);

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Bookings Found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Schedule a skill exchange session from the Explore tab to get started!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final booking = filtered[index];
              final isLearner = booking.learnerId == currentUser?.id;
              final otherUserId = isLearner ? booking.teacherId : booking.learnerId;
              final dateStr = DateFormat('EEE, MMM d, yyyy').format(booking.dateTime);
              final timeStr = DateFormat('hh:mm a').format(booking.dateTime);
              final userRepo = ref.watch(userRepositoryProvider);

              Color statusColor;
              String statusLabel;
              switch (booking.status) {
                case BookingStatus.confirmed:
                  statusColor = Colors.blue;
                  statusLabel = 'Upcoming';
                  break;
                case BookingStatus.completed:
                  statusColor = Colors.green;
                  statusLabel = 'Completed';
                  break;
                case BookingStatus.cancelled:
                  statusColor = Colors.red;
                  statusLabel = 'Cancelled';
                  break;
                default:
                  statusColor = Colors.orange;
                  statusLabel = 'Pending';
              }

              return FutureBuilder(
                future: userRepo.getUserById(otherUserId),
                builder: (context, snapshot) {
                  final otherName = snapshot.data?.name ?? 'User';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLearner
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isLearner ? 'Learner' : 'Teacher',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isLearner
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            booking.skillTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isLearner ? 'With Teacher: $otherName' : 'With Learner: $otherName',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.access_time_rounded,
                                  size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                '$timeStr (${booking.durationMins}m)',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (booking.notes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Note: ${booking.notes}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              if (booking.status == BookingStatus.confirmed) ...[
                                OutlinedButton.icon(
                                  onPressed: () => _cancelBooking(booking.id),
                                  icon: const Icon(Icons.cancel_outlined, size: 18),
                                  label: const Text('Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _completeBooking(booking.id),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Mark Completed'),
                                ),
                              ],
                              if (booking.status == BookingStatus.completed && isLearner) ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.push(
                                      '/rating/${booking.id}',
                                      extra: {
                                        'toUserId': booking.teacherId,
                                        'skillId': booking.skillId,
                                        'skillTitle': booking.skillTitle,
                                        'toUserName': otherName,
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                                  label: const Text('Leave Review'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading sessions: $err')),
      ),
    );
  }
}
