import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/dashboard/providers/dashboard_providers.dart';

/// Main shell widget with bottom NavigationBar (phone) or
/// NavigationRail (tablet/desktop >=720px).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _navItems = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      route: '/dashboard',
    ),
    _NavItem(
      label: 'Explore',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      route: '/skills',
    ),
    _NavItem(
      label: 'Chats',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      route: '/chats',
    ),
    _NavItem(
      label: 'Bookings',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
      route: '/bookings',
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: '/profile',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= AppConstants.tabletBreakpoint;
    final currentIndex = _currentIndex(context);

    final threadsAsync = ref.watch(dashboardChatsProvider);
    final unreadCount = threadsAsync.asData?.value.fold<int>(
          0,
          (sum, thread) => sum + thread.unreadCount,
        ) ??
        0;

    Widget buildIcon(_NavItem item, bool isSelected) {
      final icon = Icon(isSelected ? item.selectedIcon : item.icon);
      if (item.label == 'Chats' && unreadCount > 0) {
        return Badge(
          label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
          child: icon,
        );
      }
      return icon;
    }

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => context.go(_navItems[i].route),
              leading: const SizedBox(height: 8),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: buildIcon(item, false),
                        selectedIcon: buildIcon(item, true),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_navItems[i].route),
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: buildIcon(item, false),
                  selectedIcon: buildIcon(item, true),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
