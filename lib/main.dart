import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/dev/dummy_data_seeder.dart';
import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/onboarding/pages/onboarding_page.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/core/theme/app_theme.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:dynamic_color/dynamic_color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Debug-only dummy accounts so login is testable pre-staff-management.
  // Never runs in release builds (guarded inside + at the call site).
  if (kDebugMode) {
    await seedDummyAccounts(prefs);
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BrewlineApp(),
    ),
  );
}

/// System dynamic color (Material You on Android, accent color on
/// Windows/macOS/Linux) with the coffee-brown seed as fallback.
class BrewlineApp extends StatelessWidget {
  const BrewlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeModeProvider);

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              title: 'brewline',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: buildLightTheme(lightDynamic),
              darkTheme: buildDarkTheme(darkDynamic),
              // Route once onboarding is done: login (or straight in, if
              // already authenticated). Otherwise stay on onboarding.
              home: const _AppEntry(),
            );
          },
        );
      },
    );
  }
}

/// Chooses the first screen at launch based on onboarding + session state.
///
/// - Onboarding not completed → [OnboardingPage]
/// - Onboarding completed → [LoginPage] (the session never survives restart,
///   so every fresh launch after setup asks who is signing in).
class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingCompleteProvider);
    return onboardingComplete ? const LoginPage() : const OnboardingPage();
  }
}
