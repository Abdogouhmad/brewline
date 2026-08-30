import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePref { system, light, dark }

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

/// Controls app theme mode. Defaults to [ThemePref.system].
class ThemeController extends Notifier<ThemePref> {
  static const _key = 'theme_pref';

  @override
  ThemePref build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_key);
    return ThemePref.values.asNameMap()[stored] ?? ThemePref.system;
  }

  Future<void> setTheme(ThemePref pref) async {
    state = pref;
    await ref.read(sharedPreferencesProvider).setString(_key, pref.name);
  }

  void cycle() {
    switch (state) {
      case ThemePref.system:
        setTheme(ThemePref.light);
      case ThemePref.light:
        setTheme(ThemePref.dark);
      case ThemePref.dark:
        setTheme(ThemePref.system);
    }
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemePref>(
  ThemeController.new,
);

/// Maps the persisted preference to Material's [ThemeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  switch (ref.watch(themeControllerProvider)) {
    case ThemePref.system:
      return ThemeMode.system;
    case ThemePref.light:
      return ThemeMode.light;
    case ThemePref.dark:
      return ThemeMode.dark;
  }
});
