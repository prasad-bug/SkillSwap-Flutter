import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/app_user.dart';
import 'rating_stars.dart';

/// Card showing a user's profile summary.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
  });

  final AppUser user;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.primaryContainer,
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.initials,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: theme.textTheme.titleSmall),
                    if (user.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: cs.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            user.location,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    if (user.ratingCount > 0) ...[
                      const SizedBox(height: 4),
                      RatingStars(
                          rating: user.avgRating, count: user.ratingCount),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
