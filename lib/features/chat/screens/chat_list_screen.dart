import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/repository_providers.dart';
import '../providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final threadsAsync = ref.watch(userThreadsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: threadsAsync.when(
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Conversations Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find a skill you like and reach out to start learning!',
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

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final otherUserId = currentUser != null
                  ? thread.otherParticipantId(currentUser.id)
                  : thread.participantIds.first;

              final userRepo = ref.watch(userRepositoryProvider);

              return FutureBuilder(
                future: userRepo.getUserById(otherUserId),
                builder: (context, snapshot) {
                  final otherUser = snapshot.data;
                  final otherName = otherUser?.name ?? 'User';
                  final otherAvatar = otherUser?.avatarUrl;
                  final hasUnread = thread.unreadCount > 0;

                  String timeStr = '';
                  if (thread.lastMessageAt != null) {
                    final now = DateTime.now();
                    final diff = now.difference(thread.lastMessageAt!);
                    if (diff.inDays == 0) {
                      timeStr = DateFormat.jm().format(thread.lastMessageAt!);
                    } else if (diff.inDays < 7) {
                      timeStr = DateFormat.E().format(thread.lastMessageAt!);
                    } else {
                      timeStr = DateFormat.MMMd().format(thread.lastMessageAt!);
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: otherAvatar != null && otherAvatar.isNotEmpty
                          ? NetworkImage(otherAvatar)
                          : null,
                      child: otherAvatar == null || otherAvatar.isEmpty
                          ? Text(
                              otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hasUnread
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.lastMessage.isNotEmpty
                                  ? thread.lastMessage
                                  : 'No messages yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: hasUnread
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${thread.unreadCount}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      context.push(
                        '/chats/${thread.id}',
                        extra: {
                          'otherUserName': otherName,
                          'otherUserId': otherUserId,
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading messages: $err'),
        ),
      ),
    );
  }
}
