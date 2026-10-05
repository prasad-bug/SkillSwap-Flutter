import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/skill.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../skills/providers/skill_providers.dart';
import '../providers/booking_providers.dart';

class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({super.key, required this.skillId});
  final String skillId;

  @override
  ConsumerState<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends ConsumerState<BookingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  int _selectedDuration = 60;
  String? _errorMessage;

  final List<int> _durationOptions = [30, 60, 90, 120];

  final List<String> _availableTimeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM',
    '02:00 PM', '03:00 PM', '04:00 PM',
    '05:00 PM', '06:00 PM',
  ];

  // Returns all booked dates from user's bookings
  Set<DateTime> _getBookedDates(List<Booking> bookings) {
    return bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .map((b) => DateTime(b.dateTime.year, b.dateTime.month, b.dateTime.day))
        .toSet();
  }

  // Returns bookings for a specific day
  List<Booking> _bookingsForDay(List<Booking> bookings, DateTime day) {
    return bookings
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            b.dateTime.year == day.year &&
            b.dateTime.month == day.month &&
            b.dateTime.day == day.day)
        .toList();
  }

  DateTime _getCombinedDateTime() {
    if (_selectedTime == null) return _selectedDate;
    final format = DateFormat('hh:mm a');
    final time = format.parse(_selectedTime!);
    return DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      time.hour, time.minute,
    );
  }

  void _proceedToConfirmation(Skill skill) {
    if (_selectedTime == null) {
      setState(() => _errorMessage = 'Please select a time slot.');
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final dateTime = _getCombinedDateTime();
    final existingBookings = ref.read(userBookingsStreamProvider).asData?.value ?? [];

    final validationError = BookingValidator.validateBookingRequest(
      currentUserId: currentUser.id,
      teacherId: skill.ownerId,
      dateTime: dateTime,
      durationMins: _selectedDuration,
      existingBookings: existingBookings,
    );

    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() => _errorMessage = null);

    context.push('/skills/${widget.skillId}/confirm', extra: {
      'skill': skill,
      'dateTime': dateTime,
      'durationMins': _selectedDuration,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final skillAsync = ref.watch(skillByIdProvider(widget.skillId));
    final bookingsAsync = ref.watch(userBookingsStreamProvider);
    final allBookings = bookingsAsync.asData?.value ?? [];
    final dayBookings = _bookingsForDay(allBookings, _selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Session')),
      body: skillAsync.when(
        data: (skill) {
          if (skill == null) return const Center(child: Text('Skill not found'));

          final userRepo = ref.watch(userRepositoryProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skill card
                FutureBuilder(
                  future: userRepo.getUserById(skill.ownerId),
                  builder: (context, snapshot) {
                    final ownerName = snapshot.data?.name ?? 'Teacher';
                    return Card(
                      elevation: 0,
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: cs.primary, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(skill.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('With $ownerName', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Calendar header
                Text('1. Select Date', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Legend
                Row(
                  children: [
                    _LegendDot(color: cs.primary, label: 'Selected'),
                    const SizedBox(width: 16),
                    _LegendDot(color: Colors.orange, label: 'Has booking'),
                    const SizedBox(width: 16),
                    _LegendDot(color: cs.outlineVariant, label: 'Today'),
                  ],
                ),
                const SizedBox(height: 12),

                // TableCalendar
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TableCalendar<Booking>(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 90)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                    eventLoader: (day) => _bookingsForDay(allBookings, day),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold),
                      todayDecoration: BoxDecoration(
                        border: Border.all(color: cs.primary, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                      markerDecoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                      markerSize: 6,
                      markerMargin: const EdgeInsets.only(top: 2),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (selectedDay.isBefore(DateTime.now())) return;
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedTime = null;
                        _errorMessage = null;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                    },
                  ),
                ),

                // Show bookings for selected date
                if (dayBookings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_busy_rounded, size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              'Your bookings on ${DateFormat('MMM d').format(_selectedDate)}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...dayBookings.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.orange.shade600),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('h:mm a').format(b.dateTime)} — ${b.skillTitle.isNotEmpty ? b.skillTitle : 'Session'} (${b.durationMins}min)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Duration
                Text('2. Session Duration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: _durationOptions.map((duration) {
                    final isSelected = _selectedDuration == duration;
                    return ChoiceChip(
                      label: Text('$duration min'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() { _selectedDuration = duration; _errorMessage = null; });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Time slots
                Text('3. Select Start Time', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _availableTimeSlots.map((timeSlot) {
                    final isSelected = _selectedTime == timeSlot;
                    return ChoiceChip(
                      label: Text(timeSlot),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() { _selectedTime = selected ? timeSlot : null; _errorMessage = null; });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
                    child: Text(_errorMessage!, style: TextStyle(color: cs.onErrorContainer)),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _proceedToConfirmation(skill),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue to Confirmation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
