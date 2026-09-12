import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/app_restart.dart';
import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/core/updates/update_notifications.dart';
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/features/admin/widgets/settings/update_required_screen.dart';
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
  late final AppDatabaseHandle handle;
  try {
    prefs = await SharedPreferences.getInstance();
    // The app's single live connection lives in an [AppDatabaseHandle] so the
    // backup/restore flow can close, swap and re-open it, then restart the
    // tree below against the new connection.
    handle = AppDatabaseHandle()..attach(await openAppDatabase());
    // Seed intl with the persisted language so money/date formatting is
    // locale-aware before the first frame (§5).
    await initializeIntlLocale(storedLanguage(prefs));
  } catch (e, st) {
    developer.log('Fatal startup error: $e\n$st', name: 'brewline');
    _runErrorApp(e);
    return;
  }

  // No dummy data is seeded at startup — the app starts completely empty
  // and the admin enters real products, ingredients and staff from zero.

  // Local notifications for OTA update alerts. Deliberately best-effort: a
  // broken notification plugin (unsupported desktop environment, no permission
  // system) must never prevent the app from starting — it just disables the
  // tray/toast nudge.
  UpdateNotificationService? notifications;
  try {
    final service = UpdateNotificationService();
    await service.initialize();
    notifications = service;
  } catch (_) {
    notifications = null;
  }

  runApp(_buildApp(prefs: prefs, handle: handle, notifications: notifications));
}

/// Builds the app root with the shared [prefs], [handle] and (optional)
/// [notifications] service wired into a fresh [ProviderScope].
///
/// Called again by the [appRestartProvider] callback after a restore: runApp
/// replaces the existing tree, so every provider restarts against the
/// (possibly restored) database — the portable equivalent of the desktop OTA
/// updater's process relaunch.
Widget _buildApp({
  required SharedPreferences prefs,
  required AppDatabaseHandle handle,
  required UpdateNotificationService? notifications,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) async => handle.current),
      appDatabaseHandleProvider.overrideWithValue(handle),
      appRestartProvider.overrideWithValue(() async {
        runApp(
          _buildApp(prefs: prefs, handle: handle, notifications: notifications),
        );
      }),
      updateNotificationsProvider.overrideWithValue(notifications),
    ],
    child: const BrewlineApp(),
  );
}

/// Minimal error screen shown when the app fails to initialise.
/// Replaces the usual widget tree so the user sees *something* instead of
/// a blank / vanished window.
void _runErrorApp(Object error) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _StartupErrorView(error: '$error'),
    ),
  );
}

class _StartupErrorView extends StatelessWidget {
  final String error;

  const _StartupErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Color.lerp(kSeedColor, Colors.black, 0.6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.x2l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.errorContainer,
                size: 64,
              ),
              const SizedBox(height: Space.xl),
              Text(
                l10n.appStartupTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: Space.xl),
              Builder(
                builder: (ctx) => TextButton.icon(
                  onPressed: () {
                    // Copy error to clipboard so the user can share it.
                    final data = ClipboardData(text: error);
                    Clipboard.setData(data);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.appStartupCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.white70),
                  label: Text(
                    l10n.appStartupCopy,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            // Localization per improve.md §1.5 — delegates + supportedLocales
            // come from the generated AppLocalizations (derived from the .arb
            // files), and `locale` is an explicit override from the device-level
            // language setting (§2): null follows the OS, a value wins outright.
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: ref.watch(localeProvider),
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
    return ColoredBox(
      color: Color.lerp(kSeedColor, Colors.black, 0.6) ?? kSeedColor,
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
