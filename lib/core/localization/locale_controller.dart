import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// Languages offered in Settings → General.
///
/// The choice is a **device-level** preference, like the printer
/// configuration — whoever is standing at a given till sees whatever language
/// that device is set to, regardless of which waiter/admin is logged in. It is
/// persisted in `shared_preferences`, so it survives restarts.
enum AppLanguage {
  system(null, 'System default'),
  english(Locale('en'), 'English'),
  french(Locale('fr'), 'Français');

  const AppLanguage(this.locale, this.label);

  /// `null` for [system] — the platform locale wins.
  final Locale? locale;

  /// Human-readable name shown in dropdowns.
  final String label;
}

/// Controls the app language. Defaults to [AppLanguage.system].
///
/// System vs explicit override: `null` from [AppLanguage.system] means "follow
/// the operating system"; `MaterialApp.locale` ignores Flutter's normal
/// system-locale resolution against `supportedLocales` the moment a real
/// [Locale] is provided here. This is device-level by design (see
/// [AppLanguage]) — not per-user — so a cashier picking English on a till never
/// changes what the next waiter on that device sees.
class LanguageController extends Notifier<AppLanguage> {
  static const _key = 'language_pref';

  @override
  AppLanguage build() => storedLanguage(ref.read(sharedPreferencesProvider));

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await ref.read(sharedPreferencesProvider).setString(_key, language.name);
    // Keep intl (price/date formatting) in step with the UI language.
    await initializeIntlLocale(language);
  }
}

final languageControllerProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);

/// Maps the persisted preference to a [Locale] (`null` = follow system).
final localeProvider = Provider<Locale?>(
  (ref) => ref.watch(languageControllerProvider).locale,
);

/// Reads the persisted language preference (`system` when unset or legacy).
AppLanguage storedLanguage(SharedPreferences prefs) =>
    AppLanguage.values.asNameMap()[prefs.getString(LanguageController._key)] ??
    AppLanguage.system;

/// Maps an [AppLanguage] to the intl locale code used by the number/date
/// display helpers. `system` resolves the platform's language, falling back
/// to English when it speaks neither supported language.
String resolveIntlLocale(AppLanguage language) {
  switch (language) {
    case AppLanguage.system:
      final system = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      return system == 'fr' ? 'fr' : 'en';
    case AppLanguage.english:
      return 'en';
    case AppLanguage.french:
      return 'fr';
  }
}

/// Seeds intl with the app's language so `NumberFormat` / `DateFormat` (the
/// price/date display helpers in `core/utils`) render amounts and dates in the
/// chosen language even in code paths without a `BuildContext`.
///
/// English number/date symbols ship inside intl; French's are loaded lazily via
/// `initializeDateFormatting`. Both locales are initialised eagerly so a
/// mid-session switch to French can never hit an uninitialized locale.
Future<String> initializeIntlLocale(AppLanguage language) async {
  final code = resolveIntlLocale(language);
  Intl.defaultLocale = code;
  await initializeDateFormatting('en');
  await initializeDateFormatting('fr');
  return code;
}
