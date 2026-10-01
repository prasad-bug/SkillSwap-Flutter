import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/skills/screens/skill_listing_screen.dart';
import '../../features/skills/screens/skill_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/booking/screens/booking_calendar_screen.dart';
import '../../features/booking/screens/confirm_session_screen.dart';
import '../../features/booking/screens/my_bookings_screen.dart';
import '../../features/rating/screens/rating_screen.dart';
import '../widgets/app_shell.dart';

// ─── Route names ─────────────────────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const skillListing = '/skills';
  static const skillDetail = '/skills/:skillId';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const chatList = '/chats';
  static const chat = '/chats/:threadId';
  static const myBookings = '/bookings';
  static const bookingCalendar = '/skills/:skillId/book';
  static const confirmSession = '/skills/:skillId/confirm';
  static const rating = '/rating/:bookingId';
}

// ─── Router provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isOnAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isOnAuth) return AppRoutes.login;
      if (isLoggedIn && state.matchedLocation == AppRoutes.login) {
        return AppRoutes.dashboard;
      }
      if (isLoggedIn && state.matchedLocation == AppRoutes.signup) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: AppRoutes.splash,
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (ctx, state) => const SignupScreen(),
      ),

      // Main app shell (bottom nav)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (ctx, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.skillListing,
            builder: (ctx, state) {
              final category =
                  state.uri.queryParameters['category'];
              return SkillListingScreen(initialCategory: category);
            },
            routes: [
              GoRoute(
                path: ':skillId',
                builder: (ctx, state) => SkillDetailScreen(
                    skillId: state.pathParameters['skillId']!),
                routes: [
                  GoRoute(
                    path: 'book',
                    builder: (ctx, state) => BookingCalendarScreen(
                        skillId: state.pathParameters['skillId']!),
                  ),
                  GoRoute(
                    path: 'confirm',
                    builder: (ctx, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return ConfirmSessionScreen(
                        skillId: state.pathParameters['skillId']!,
                        bookingData: extra ?? {},
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (ctx, state) {
              final userId = state.uri.queryParameters['userId'];
              return ProfileScreen(userId: userId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (ctx, state) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.chatList,
            builder: (ctx, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: ':threadId',
                builder: (ctx, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return ChatScreen(
                    threadId: state.pathParameters['threadId']!,
                    otherUserName: extra?['otherUserName'] as String? ?? '',
                    otherUserId: extra?['otherUserId'] as String? ?? '',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.myBookings,
            builder: (ctx, state) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: '/rating/:bookingId',
            builder: (ctx, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return RatingScreen(
                bookingId: state.pathParameters['bookingId']!,
                toUserId: extra?['toUserId'] as String? ?? '',
                skillId: extra?['skillId'] as String? ?? '',
                skillTitle: extra?['skillTitle'] as String? ?? '',
                toUserName: extra?['toUserName'] as String? ?? '',
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
