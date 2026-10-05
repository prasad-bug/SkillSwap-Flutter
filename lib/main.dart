import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'data/firebase/firestore_seed_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppConstants.isFirebaseAvailable = true;

    // Seed initial realistic demo data if Firestore is empty
    if (!AppConstants.useMockRepo) {
      await FirestoreSeedService().seedIfEmpty();
    }
  } catch (e) {
    debugPrint('Firebase initialization status: $e');
    AppConstants.isFirebaseAvailable = false;
  }

  runApp(
    const ProviderScope(
      child: SkillSwapApp(),
    ),
  );
}

class SkillSwapApp extends ConsumerWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
