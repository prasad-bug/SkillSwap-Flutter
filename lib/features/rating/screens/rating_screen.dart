import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/rating.dart';

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({
    super.key,
    required this.bookingId,
    required this.toUserId,
    required this.skillId,
    required this.skillTitle,
    required this.toUserName,
  });

  final String bookingId;
  final String toUserId;
  final String skillId;
  final String skillTitle;
  final String toUserName;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _selectedStars = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final rating = Rating(
        id: 'rate_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: widget.bookingId,
        fromUserId: currentUser.id,
        toUserId: widget.toUserId,
        stars: _selectedStars,
        review: _reviewController.text.trim(),
        createdAt: DateTime.now(),
        skillId: widget.skillId,
        skillTitle: widget.skillTitle,
        fromUserName: currentUser.name,
        fromUserAvatarUrl: currentUser.avatarUrl,
      );

      await ref.read(ratingRepositoryProvider).submitRating(rating);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.stars_rounded, color: Colors.amber, size: 56),
            title: const Text('Rating Submitted!'),
            content: const Text(
              'Thank you for sharing your feedback! Your review helps build trust within the SkillSwap peer network.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/profile');
                },
                child: const Text('View Profile'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                widget.toUserName.isNotEmpty ? widget.toUserName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was your session with ${widget.toUserName}?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.skillTitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Skill: ${widget.skillTitle}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNum = index + 1;
                final isSelected = starNum <= _selectedStars;
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : theme.colorScheme.outlineVariant,
                  ),
                  onPressed: () {
                    setState(() => _selectedStars = starNum);
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getStarText(_selectedStars),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Feedback',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share details of your experience, what went well, or what you learned...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStarText(int stars) {
    switch (stars) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
