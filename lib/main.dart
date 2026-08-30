import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/db/app_database.dart';
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
  final db = await openAppDatabase();

  // Debug-only dummy accounts + sample sales so the flows and dashboards are
  // testable before real data exists. Never runs in release builds.
  if (kDebugMode) {
    await seedDummyAccounts(prefs, db);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) async => db),
      ],
      child: const BrewlineApp(),
    ),
  );
}

/// System dynamic color (Material You on Android, accent color on desktop)
/// with the coffee-brown seed as fallback.
class BrewlineApp extends StatelessWidget {
  const BrewlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PaletteGate(child: _ThemedApp());
  }
}

/// Waits until the platform's dynamic color palette has resolved before
/// building the themed app, so the UI never paints a placeholder scheme and
/// snaps to the real one a frame later (the coffee→native-accent flash seen on
/// desktop). A flat neutral background covers the gap.
///
/// If the platform never answers (no GTK accent, very old embedders), a short
/// grace period time-boxes the wait and the app proceeds with the coffee seed.
class _PaletteGate extends StatefulWidget {
  const _PaletteGate({required this.child});

  final Widget child;

  @override
  State<_PaletteGate> createState() => _PaletteGateState();
}

class _PaletteGateState extends State<_PaletteGate> {
  Timer? _timer;
  bool _gaveUp = false;

  /// How long the splash may hold before we stop waiting on the platform.
  /// Resolution is near-instant where supported, so this only ever fires on
  /// platforms that never answer.
  static const Duration _gracePeriod = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _timer = Timer(_gracePeriod, () {
      if (mounted) setState(() => _gaveUp = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final resolved = lightDynamic != null && darkDynamic != null;
        final showApp = resolved || _gaveUp;

        return Consumer(
          builder: (context, ref, _) => MaterialApp(
            title: 'brewline',
            debugShowCheckedModeBanner: false,
            // buildLightTheme(null) falls back to the coffee seed, so the
            // scheme is safe to pass straight through.
            theme: buildLightTheme(lightDynamic),
            darkTheme: buildDarkTheme(darkDynamic),
            themeMode: showApp
                ? ref.watch(themeModeProvider)
                : ThemeMode.system,
            home: showApp ? widget.child : const _LaunchBackground(),
          ),
        );
      },
    );
  }
}

/// The real app root, shown once the palette is resolved.
class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return const _AppEntry();
  }
}

/// Flat, theme-independent launch background shown while the platform accent
/// resolves. Fixed color so the first frames can't flicker between schemes.
class _LaunchBackground extends StatelessWidget {
  const _LaunchBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF241B13));
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
