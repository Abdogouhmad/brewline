import 'package:brewline/features/onboarding/pages/onboarding_page.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/theme/app_theme.dart';
import 'package:brewline/core/theme/theme_controller.dart';

// import 'package:brewline/features/waiter/pages/waiter_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

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
              // TODO: route based on onboarding-completed flag (auth feature).
              // Admin profile entry point: features/admin/.../admin_home_page.dart
              home: const OnboardingPage(),
            );
          },
        );
      },
    );
  }
}
