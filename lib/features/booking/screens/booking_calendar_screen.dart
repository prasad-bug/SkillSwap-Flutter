import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/skill.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../skills/providers/skill_providers.dart';
import '../providers/booking_providers.dart';

class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({
    super.key,
    required this.skillId,
  });

  final String skillId;

  @override
  ConsumerState<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends ConsumerState<BookingCalendarScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  int _selectedDuration = 60;
  String? _errorMessage;

  final List<int> _durationOptions = [30, 60, 90, 120];

  final List<String> _availableTimeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  DateTime _getCombinedDateTime() {
    if (_selectedTime == null) return _selectedDate;
    final format = DateFormat('hh:mm a');
    final time = format.parse(_selectedTime!);
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
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
    final existingBookingsAsync = ref.read(userBookingsStreamProvider);
    final existingBookings = existingBookingsAsync.asData?.value ?? [];

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

    context.push(
      '/skills/${widget.skillId}/confirm',
      extra: {
        'skill': skill,
        'dateTime': dateTime,
        'durationMins': _selectedDuration,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skillAsync = ref.watch(skillByIdProvider(widget.skillId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Session'),
      ),
      body: skillAsync.when(
        data: (skill) {
          if (skill == null) {
            return const Center(child: Text('Skill not found'));
          }

          final userRepo = ref.watch(userRepositoryProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder(
                  future: userRepo.getUserById(skill.ownerId),
                  builder: (context, snapshot) {
                    final ownerName = snapshot.data?.name ?? 'Teacher';
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    skill.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'With $ownerName',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
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

                Text(
                  '1. Select Date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                        _errorMessage = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  '2. Session Duration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _durationOptions.map((duration) {
                    final isSelected = _selectedDuration == duration;
                    return ChoiceChip(
                      label: Text('$duration min'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedDuration = duration;
                            _errorMessage = null;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Text(
                  '3. Select Start Time',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableTimeSlots.map((timeSlot) {
                    final isSelected = _selectedTime == timeSlot;
                    return ChoiceChip(
                      label: Text(timeSlot),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTime = selected ? timeSlot : null;
                          _errorMessage = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _proceedToConfirmation(skill),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue to Confirmation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
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
