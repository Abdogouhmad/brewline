import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/features/admin/settings/widgets/update_required_screen.dart';
import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/onboarding/pages/onboarding_page.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/core/theme/app_theme.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:dynamic_color/dynamic_color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap the entire startup in a guard so any unhandled exception (database,
  // plugin, or platform API failure) surfaces as an actionable error screen
  // instead of silently killing the process — especially important on Windows
  // where a bare crash gives the user no feedback at all.
  late final SharedPreferences prefs;
  late final Database db;
  try {
    prefs = await SharedPreferences.getInstance();
    db = await openAppDatabase();
  } catch (e, st) {
    developer.log('Fatal startup error: $e\n$st', name: 'brewline');
    _runErrorApp(e);
    return;
  }

  // No dummy data is seeded at startup — the app starts completely empty and
  // the admin enters real products, ingredients and staff from zero.

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

/// Minimal error screen shown when the app fails to initialise.
/// Replaces the usual widget tree so the user sees *something* instead of
/// a blank / vanished window.
void _runErrorApp(Object error) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF241B13),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'brewline failed to start',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (ctx) => TextButton.icon(
                    onPressed: () {
                      // Copy error to clipboard so the user can share it.
                      final data = ClipboardData(text: '$error');
                      Clipboard.setData(data);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Error copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    label: const Text('Copy error',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    return const UpdateAppGate(child: _AppEntry());
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

/// Wraps the app with the OTA update machinery:
/// - triggers the background auto-check once at startup when enabled,
/// - layers the non-dismissible [UpdateRequiredScreen] over everything when a
///   **mandatory** update arrives.
///
/// The auto-check is fire-and-forget and never blocks startup; a failed check
/// is silent. Only a mandatory result takes over the whole app.
class UpdateAppGate extends ConsumerStatefulWidget {
  const UpdateAppGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateAppGate> createState() => _UpdateAppGateState();
}

class _UpdateAppGateState extends ConsumerState<UpdateAppGate> {
  bool _startedCheck = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedCheck) return;
    _startedCheck = true;

    // Kick off the background check without awaiting it — startup must never
    // block on the network.
    final autoCheck = ref.read(autoCheckUpdatesProvider);
    if (autoCheck && !kIsWeb) {
      Future<void>.microtask(() {
        if (mounted) {
          ref.read(updateProvider.notifier).checkForUpdates();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final updater = ref.watch(updateProvider);

    // Mandatory updates take over the whole app regardless of which screen
    // (login, waiter home, admin dashboard) is showing.
    if (updater.isMandatory) {
      return const UpdateRequiredScreen();
    }

    return widget.child;
  }
}
