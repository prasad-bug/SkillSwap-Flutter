import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/repository_providers.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.otherUserName,
    required this.otherUserId,
  });

  final String threadId;
  final String otherUserName;
  final String otherUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _showSmartCard = true;
  bool _showBottomSheet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        ref.read(chatRepositoryProvider).markMessagesRead(widget.threadId, user.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            widget.threadId,
            user.id,
            text,
          );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _openBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingBottomSheet(
        otherUserName: widget.otherUserName.isEmpty ? 'Maya Lin' : widget.otherUserName,
        onPropose: () {
          Navigator.pop(ctx);
          _messageController.text = '📅 Proposed a 45-min SkillSwap session for Friday, Oct 27 at 3:00 PM.';
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final messagesAsync = ref.watch(threadMessagesStreamProvider(widget.threadId));
    final currentUser = ref.watch(currentUserProvider).value;
    
    final displayName = widget.otherUserName.isEmpty ? 'Maya Lin' : widget.otherUserName;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.sync_alt_rounded, color: cs.onPrimary, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chat Conversation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: cs.surfaceContainer,
              backgroundImage: const CachedNetworkImageProvider('https://i.pravatar.cc/150?img=16'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sub-header Profile Bar & Context Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _SubHeaderProfileBar(displayName: displayName),
                  const SizedBox(height: 12),
                  _SwapMatchBanner(displayName: displayName),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Today, October 24',
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            
            // Messages List
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + (_showSmartCard ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _showSmartCard) {
                        return _SmartSuggestionCard(
                          onDismiss: () => setState(() => _showSmartCard = false),
                          onBook: _openBookingSheet,
                        );
                      }
                      
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUser?.id;
                      final timeStr = DateFormat.jm().format(msg.timestamp);

                      return _ChatMessageBubble(
                        text: msg.text,
                        time: timeStr,
                        isMe: isMe,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
            
            // Quick Chips
            _QuickChipsCarousel(
              onTapChip: (text) {
                _messageController.text = text;
              },
              onBookTap: _openBookingSheet,
            ),
            
            // Input Field Dock
            _InputDock(
              controller: _messageController,
              isSending: _isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Header Profile Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SubHeaderProfileBar extends StatelessWidget {
  const _SubHeaderProfileBar({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?img=5'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // green
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surfaceContainerLowest, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded, size: 16, color: cs.primary),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Usually responds in 15m', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _CircleBtn(icon: Icons.call_rounded),
              const SizedBox(width: 4),
              _CircleBtn(icon: Icons.videocam_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: cs.surfaceContainerLow, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: cs.primary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contextual Swap Banner
// ─────────────────────────────────────────────────────────────────────────────
class _SwapMatchBanner extends StatelessWidget {
  const _SwapMatchBanner({required this.displayName});
  final String displayName;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final firstName = displayName.split(' ').first;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [cs.primaryFixed, cs.secondaryContainer.withValues(alpha: 0.5)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.swap_horiz_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('PERFECT SWAP MATCH', style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(width: 4),
                    const Text('✨', style: TextStyle(fontSize: 12)),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
                    children: [
                      TextSpan(text: '$firstName wants '),
                      const TextSpan(text: 'French 🇫🇷', style: TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: ' • Offers '),
                      const TextSpan(text: 'Figma Systems', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: cs.surfaceContainerLowest.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(100)),
            child: Text('Match 98%', style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Message Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.text, required this.time, required this.isMe});
  final String text;
  final String time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(radius: 14, backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?img=5')),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isMe ? cs.primary : cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all_rounded, size: 14, color: cs.primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart Suggestion Card
// ─────────────────────────────────────────────────────────────────────────────
class _SmartSuggestionCard extends StatelessWidget {
  const _SmartSuggestionCard({required this.onDismiss, required this.onBook});
  final VoidCallback onDismiss;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: cs.primaryFixed, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.handshake_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ready to Lock in a Time?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('No currency • 1:1 Skill barter session', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You Offer (25m)', style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Conversational French', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Maya Offers (25m)', style: theme.textTheme.labelSmall?.copyWith(color: cs.secondary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Figma Auto-layout', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: cs.primaryFixed, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text('Fri, Oct 27 • 3:00 PM', style: theme.textTheme.labelMedium?.copyWith(color: cs.onPrimaryFixed, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text('Thu, Oct 26 • 4:30 PM', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: onBook,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('Send Booking Request'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: onBook,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.surfaceContainer,
                      foregroundColor: cs.onSurface,
                    ),
                    child: const Text('Custom'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Chips Carousel
// ─────────────────────────────────────────────────────────────────────────────
class _QuickChipsCarousel extends StatelessWidget {
  const _QuickChipsCarousel({required this.onTapChip, required this.onBookTap});
  final ValueChanged<String> onTapChip;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            cs: cs,
            icon: Icons.calendar_month_rounded,
            label: 'Book session with Maya',
            bgColor: cs.primaryFixed,
            textColor: cs.primary,
            iconColor: cs.primary,
            onTap: onBookTap,
          ),
          const SizedBox(width: 8),
          _buildChip(
            cs: cs,
            icon: Icons.schedule_rounded,
            label: 'Suggest Friday 3 PM',
            bgColor: cs.surfaceContainerLowest,
            textColor: cs.onSurface,
            iconColor: cs.secondary,
            onTap: () => onTapChip('Friday at 3:00 PM works great for me! Shall we lock that in?'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            cs: cs,
            icon: Icons.auto_awesome_rounded,
            label: 'Propose 1:1 Swap',
            bgColor: cs.surfaceContainerLowest,
            textColor: cs.onSurface,
            iconColor: cs.tertiary,
            onTap: () => onTapChip('Let\'s propose a 45-min bilateral swap: 20m French & 25m Figma!'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Dock
// ─────────────────────────────────────────────────────────────────────────────
class _InputDock extends StatelessWidget {
  const _InputDock({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: cs.onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.sentiment_satisfied_rounded, color: cs.onSurfaceVariant),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Message Maya...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic_rounded, color: cs.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
              child: isSending
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Icon(Icons.send_rounded, color: cs.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BookingBottomSheet extends StatelessWidget {
  const _BookingBottomSheet({required this.otherUserName, required this.onPropose});
  final String otherUserName;
  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 6,
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: cs.primaryFixed, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.calendar_today_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skill Barter Session', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Coordinated live via Google Meet', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?img=5'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$otherUserName • Senior UI Designer', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Paris time (GMT+2) • 100% Barter rate', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Select Exchange Format', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cs.primaryFixed, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Split Session', style: theme.textTheme.labelMedium?.copyWith(color: cs.onPrimaryFixed, fontWeight: FontWeight.bold)),
                            Icon(Icons.check_circle_rounded, size: 18, color: cs.onPrimaryFixed),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('45 Mins (20 FR + 25 Figma)', style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimaryFixed)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Deep Dive', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                            Icon(Icons.circle_outlined, size: 18, color: cs.onSurfaceVariant),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('60 Mins (Equal 30m/30m)', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Select Proposed Time', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_available_rounded, color: cs.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Friday, Oct 27 • 3:00 PM', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Both available based on calendar link', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  Radio(value: 1, groupValue: 1, onChanged: (v){}, activeColor: cs.primary),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_rounded, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thursday, Oct 26 • 4:30 PM', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Alternative afternoon window', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  Radio(value: 2, groupValue: 1, onChanged: (v){}, activeColor: cs.primary),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onPropose,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Propose This Swap to Maya'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
