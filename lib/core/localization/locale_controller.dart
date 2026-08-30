import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// Languages offered in Settings → General.
enum AppLanguage {
  system(null, 'System'),
  english(Locale('en'), 'English'),
  arabic(Locale('ar'), 'العربية');

  const AppLanguage(this.locale, this.label);

  /// `null` for [system] — the platform locale wins.
  final Locale? locale;

  /// Human-readable name shown in dropdowns.
  final String label;
}

/// Controls the app language. Defaults to [AppLanguage.system].
///
/// TODO: wire [localeProvider] into `MaterialApp` once .arb
/// localizations land; for now the choice is only persisted.
class LanguageController extends Notifier<AppLanguage> {
  static const _key = 'language_pref';

  @override
  AppLanguage build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_key);
    return AppLanguage.values.asNameMap()[stored] ?? AppLanguage.system;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await ref.read(sharedPreferencesProvider).setString(_key, language.name);
  }
}

final languageControllerProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);

/// Maps the persisted preference to a [Locale] (`null` = follow system).
final localeProvider = Provider<Locale?>(
  (ref) => ref.watch(languageControllerProvider).locale,
);
