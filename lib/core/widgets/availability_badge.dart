import 'package:flutter/material.dart';
import '../../data/models/skill.dart';

/// A dot + label badge indicating availability status.
/// Uses color AND icon/label (not color alone) for accessibility.
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final AvailabilityStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label, icon) = switch (status) {
      AvailabilityStatus.available => (
          const Color(0xFF22C55E),
          'Available',
          Icons.circle,
        ),
      AvailabilityStatus.limited => (
          const Color(0xFFF59E0B),
          'Limited',
          Icons.circle,
        ),
      AvailabilityStatus.unavailable => (
          theme.colorScheme.error,
          'Unavailable',
          Icons.do_not_disturb_on,
        ),
    };

    return Semantics(
      label: 'Availability: $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          if (!compact)
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (compact)
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
