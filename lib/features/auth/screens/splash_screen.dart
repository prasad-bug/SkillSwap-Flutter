import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/repository_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProvider);

    // Navigate based on auth state
    authState.when(
      data: (user) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user != null) {
            context.go('/dashboard');
          } else {
            context.go('/login');
          }
        });
      },
      loading: () {},
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
      },
    );

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.onPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.swap_horiz_rounded,
                  size: 56, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'SkillSwap',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exchange skills, grow together',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: cs.onPrimary,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
