import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/skill.dart';
import '../../../data/models/booking.dart';

class ConfirmSessionScreen extends ConsumerStatefulWidget {
  const ConfirmSessionScreen({
    super.key,
    required this.skillId,
    required this.bookingData,
  });

  final String skillId;
  final Map<String, dynamic> bookingData;

  @override
  ConsumerState<ConfirmSessionScreen> createState() => _ConfirmSessionScreenState();
}

class _ConfirmSessionScreenState extends ConsumerState<ConfirmSessionScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking(Skill skill, DateTime dateTime, int durationMins) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final newBooking = Booking(
        id: 'book_${DateTime.now().millisecondsSinceEpoch}',
        skillId: skill.id,
        skillTitle: skill.title,
        teacherId: skill.ownerId,
        learnerId: currentUser.id,
        dateTime: dateTime,
        durationMins: durationMins,
        status: BookingStatus.confirmed,
        notes: _notesController.text.trim(),
      );

      await ref.read(bookingRepositoryProvider).createBooking(newBooking);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
            title: const Text('Session Booked!'),
            content: const Text(
              'Your skill exchange session has been successfully booked. You can view it in your bookings schedule.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/bookings');
                },
                child: const Text('View My Bookings'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skill = widget.bookingData['skill'] as Skill?;
    final dateTime = widget.bookingData['dateTime'] as DateTime?;
    final durationMins = (widget.bookingData['durationMins'] as int?) ?? 60;

    if (skill == null || dateTime == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Session')),
        body: const Center(child: Text('Invalid booking request parameters.')),
      );
    }

    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(dateTime);
    final formattedTime = DateFormat('hh:mm a').format(dateTime);
    final userRepo = ref.watch(userRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: userRepo.getUserById(skill.ownerId),
              builder: (context, snapshot) {
                final teacherName = snapshot.data?.name ?? 'Teacher';
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          context,
                          icon: Icons.school_rounded,
                          label: 'Skill',
                          value: skill.title,
                        ),
                        const SizedBox(height: 14),
                        _buildSummaryRow(
                          context,
                          icon: Icons.person_rounded,
                          label: 'Teacher',
                          value: teacherName,
                        ),
                        const SizedBox(height: 14),
                        _buildSummaryRow(
                          context,
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: formattedDate,
                        ),
                        const SizedBox(height: 14),
                        _buildSummaryRow(
                          context,
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: '$formattedTime ($durationMins minutes)',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Add a Note for the Teacher (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share what you hope to learn or questions you have...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _confirmBooking(skill, dateTime, durationMins),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Confirm & Book Session',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
