import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  int _currentStep = 1;
  int _selectedRating = 5;
  final Set<String> _selectedTags = {};
  bool _showRewardPopup = false;
  bool _isRatingSubmitted = false;

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _copyLink() {
    Clipboard.setData(const ClipboardData(text: 'https://meet.google.com/skw-figma-lin'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 2)),
    );
  }

  void _submitRating() {
    setState(() {
      _isRatingSubmitted = true;
      _showRewardPopup = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showRewardPopup = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.85),
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
                Text('Bookings', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications_none_rounded, color: cs.onSurfaceVariant), onPressed: (){}),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withValues(alpha: 0.2),
              backgroundImage: const CachedNetworkImageProvider('https://i.pravatar.cc/150?img=16'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressIndicator(cs, theme),
                const SizedBox(height: 20),
                if (_currentStep == 1) _buildStep1(cs, theme),
                if (_currentStep == 2) _buildStep2(cs, theme),
                if (_currentStep == 3) _buildStep3(cs, theme),
              ],
            ),
          ),
          if (_showRewardPopup)
            Positioned(
              bottom: 24, left: 16, right: 16,
              child: _buildRewardPopup(cs, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme cs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 24, right: 24,
            child: Container(height: 4, color: cs.surfaceContainerHigh),
          ),
          Positioned(
            left: 24,
            right: _currentStep == 1 ? null : (_currentStep == 2 ? MediaQuery.of(context).size.width * 0.4 : 24),
            child: Container(
              height: 4,
              color: cs.primaryContainer,
              width: _currentStep == 1 ? 0 : (_currentStep == 2 ? MediaQuery.of(context).size.width * 0.4 : double.infinity),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepBadge(1, 'Date & Time', cs, theme),
              _buildStepBadge(2, 'Review', cs, theme),
              _buildStepBadge(3, 'Confirmed', cs, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge(int step, String label, ColorScheme cs, ThemeData theme) {
    bool isActive = _currentStep == step;
    bool isDone = _currentStep > step;

    Color bgColor = isActive ? cs.primaryContainer : (isDone ? cs.secondary : cs.surfaceContainerHigh);
    Color fgColor = isActive ? cs.onPrimaryContainer : (isDone ? cs.onSecondary : cs.onSurfaceVariant);
    Color textColor = isActive ? cs.primary : (isDone ? cs.secondary : cs.onSurfaceVariant);

    return GestureDetector(
      onTap: () => _goToStep(step),
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : null),
            child: Center(
              child: isDone
                  ? Icon(Icons.check_rounded, color: fgColor, size: 18)
                  : Text('$step', style: theme.textTheme.labelMedium?.copyWith(color: fgColor, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: textColor, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStep1(ColorScheme cs, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partner Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(radius: 24, backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?img=5')),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(width: 12, height: 12, decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle, border: Border.all(color: cs.surfaceContainerLowest, width: 2))),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Maya Lin', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(100)),
                          child: Text('Pro Partner', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text('Figma Design Systems • 45m swap', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Calendar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('October 2025', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 20), onPressed: (){}, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                      IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 20), onPressed: (){}, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Dummy Calendar Image/Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mo','Tu','We','Th','Fr','Sa','Su'].map((d) => Text(d, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))).toList(),
              ),
              const SizedBox(height: 12),
              // simplified grid for the prototype
              SizedBox(
                height: 200,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: 35,
                  itemBuilder: (ctx, i) {
                    int day = i - 1; // start Oct 1 on Wed
                    if (day < 1 || day > 31) return const SizedBox();
                    bool isSelected = day == 24;
                    bool hasDot = [7,9,15,17,21,22,28].contains(day);
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primaryContainer : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text('$day', style: TextStyle(color: isSelected ? cs.onPrimaryContainer : cs.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          if (hasDot && !isSelected)
                            Positioned(bottom: 4, child: Container(width: 4, height: 4, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle))),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Available', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 16),
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Selected (Thu, Oct 24)', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Time Slots
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Available Slots', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('PDT (UTC-7)', style: theme.textTheme.labelSmall?.copyWith(color: cs.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.5,
                children: [
                  _buildSlot(cs, '10:00 AM', false, false),
                  _buildSlot(cs, '2:00 PM', true, false),
                  _buildSlot(cs, '3:30 PM', true, true),
                  _buildSlot(cs, '5:00 PM', true, false),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Exchange Type
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment / Exchange Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio(value: 1, groupValue: 1, onChanged: (v){}, activeColor: cs.primary),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Direct 1:1 Skill Swap', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(100)),
                                child: Text('0 Credits', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              children: const [
                                TextSpan(text: 'You teach: '),
                                TextSpan(text: 'French Conversation (45m)', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' in mutual exchange.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio(value: 2, groupValue: 1, onChanged: (v){}, activeColor: cs.primary),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Use 1 Swap Credit', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('(Balance: 4 credits)', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Maya Lin claims 1 credit upon completed session.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Notes
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notes for Maya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                controller: TextEditingController(text: 'Looking forward to reviewing my component library structure, design token naming conventions, and best practices for responsive autolayout!'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('124 / 300 characters', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => _goToStep(2),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            iconAlignment: IconAlignment.end,
            label: const Text('Continue to Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlot(ColorScheme cs, String time, bool available, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: cs.secondaryContainer, width: 2) : null,
        boxShadow: selected ? [BoxShadow(color: cs.secondaryContainer.withValues(alpha: 0.3), blurRadius: 4)] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.schedule_rounded,
                size: 16,
                color: selected ? cs.secondaryContainer : (available ? cs.primary : cs.outline),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  decoration: available ? null : TextDecoration.lineThrough,
                  color: selected ? cs.onPrimaryContainer : (available ? cs.onSurface : cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          if (selected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(100)),
              child: Text('Selected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer)),
            )
          else
            Text(
              available ? 'Open' : 'Booked',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: available ? cs.secondary : cs.outline),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Exchange Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: cs.primaryFixed, borderRadius: BorderRadius.circular(100)),
                    child: Text('Mutual Barter', style: theme.textTheme.labelSmall?.copyWith(color: cs.onPrimaryFixedVariant, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Matrix
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.school_rounded, size: 14, color: cs.primary),
                                  const SizedBox(width: 4),
                                  Text('YOU LEARN', style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Figma Systems', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('with Maya Lin', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('YOU TEACH', style: theme.textTheme.labelSmall?.copyWith(color: cs.secondary, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.record_voice_over_rounded, size: 14, color: cs.secondary),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('French Chat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Conversation Prep', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                    child: Icon(Icons.sync_alt_rounded, color: cs.onSecondary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detail Rows
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildDetailRow(cs, Icons.calendar_today_rounded, cs.primary, 'Date & Time', 'Thursday, Oct 24, 2025 • 3:30 PM'),
                    const SizedBox(height: 12),
                    _buildDetailRow(cs, Icons.timelapse_rounded, cs.secondary, 'Duration', '45 Minutes session'),
                    const SizedBox(height: 12),
                    _buildDetailRow(cs, Icons.videocam_rounded, cs.tertiary, 'Location', 'Google Meet (Auto-generated link)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes Preview
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Included Notes:', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '“Looking forward to reviewing my component library structure, design token naming conventions, and best practices for responsive autolayout!”',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Free cancellation up to 6 hours before meeting. SkillSwap Guarantee protects both partners with automatic credit refunds.',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => _goToStep(3),
            icon: const Icon(Icons.event_available_rounded, size: 20),
            label: const Text('Confirm & Schedule Exchange', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => _goToStep(1),
            style: TextButton.styleFrom(
              backgroundColor: cs.surfaceContainerLow,
              foregroundColor: cs.onSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Edit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ColorScheme cs, IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle),
                child: Icon(Icons.celebration_rounded, color: cs.onSecondary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎉 Session Confirmed!', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold)),
                    Text('Added to Google Calendar & SkillSwap chat.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSecondaryContainer)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UPCOMING BARTER SESSION', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1)),
                      Text('Figma Design Systems', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: cs.surfaceContainerHigh, shape: BoxShape.circle),
                    child: Icon(Icons.video_chat_rounded, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scheduled Date', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                          Text('Oct 24, 2025', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Exact Time', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                          Text('3:30 - 4:15 PM', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, color: cs.secondary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('meet.google.com/skw-figma-lin', style: TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    FilledButton(
                      onPressed: _copyLink,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Copy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: (){},
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('Message Maya'),
                      style: TextButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHigh,
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (){},
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: const Text('Sync Cal'),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('POST-SESSION EXPERIENCE FLOW', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cs.tertiaryFixed, borderRadius: BorderRadius.circular(100)),
              child: Text('Interactive Preview', style: theme.textTheme.labelSmall?.copyWith(color: cs.onTertiaryFixed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  const CircleAvatar(radius: 28, backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?img=5')),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                      child: Icon(Icons.check_rounded, color: cs.onPrimary, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Rate your session with Maya Lin', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('How was your Figma design systems exchange?', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(Icons.star_rounded, size: 36),
                    color: index < _selectedRating ? cs.tertiaryFixedDim : cs.outlineVariant,
                    onPressed: () => setState(() => _selectedRating = index + 1),
                  );
                }),
              ),
              Text(
                _selectedRating == 5 ? 'Exceptional mentor! ⭐️' : 'Good session',
                style: theme.textTheme.labelMedium?.copyWith(color: cs.tertiary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text('What stood out?', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['Patient', 'Clear Explanations', 'Super Prepared', 'Great Energy'].map((tag) {
                  bool isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) _selectedTags.remove(tag);
                        else _selectedTags.add(tag);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primaryFixed : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(tag, style: theme.textTheme.labelMedium?.copyWith(color: isSelected ? cs.onPrimaryFixedVariant : cs.onSurfaceVariant, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Share a few words for the community', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Maya's breakdown of design tokens made everything click instantly...",
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isRatingSubmitted ? null : _submitRating,
                  icon: Icon(_isRatingSubmitted ? Icons.done_all_rounded : Icons.send_rounded, size: 20),
                  label: Text(_isRatingSubmitted ? 'Rating Submitted!' : 'Submit Rating', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardPopup(ColorScheme cs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: cs.tertiaryFixed, shape: BoxShape.circle),
            child: const Center(child: Text('⚡', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('+1 Swap Credit Earned!', style: theme.textTheme.titleMedium?.copyWith(color: cs.onInverseSurface, fontWeight: FontWeight.bold)),
                Text('Thank you for rating Maya Lin!', style: theme.textTheme.bodySmall?.copyWith(color: cs.onInverseSurface.withValues(alpha: 0.8))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onInverseSurface.withValues(alpha: 0.7)),
            onPressed: () => setState(() => _showRewardPopup = false),
          ),
        ],
      ),
    );
  }
}
