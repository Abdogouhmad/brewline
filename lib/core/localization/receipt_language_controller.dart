import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// Language printed receipts are generated in — **independent** of the UI's
/// language (improve.md §6, Option A).
///
/// Device-level, like [PrinterSettings]: whoever stands at a till prints in
/// the language that till is configured to. Defaults to French because the
/// customer holding the paper has no relationship to the staff's UI choice.
enum ReceiptLanguage {
  french('fr', 'Français'),
  english('en', 'English');

  const ReceiptLanguage(this.code, this.label);

  /// intl locale code passed to the receipt templates / formatters.
  final String code;

  /// Human-readable name shown in the Printer settings dropdown.
  final String label;
}

/// Persists the receipt language under a single SharedPreferences key, mirror-
/// loading [AppLanguage] so `ReceiptLanguage.french` stays the fallback for
/// unset/legacy values.
class ReceiptLanguageController extends Notifier<ReceiptLanguage> {
  static const _key = 'receipt_language';

  @override
  ReceiptLanguage build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_key);
    return ReceiptLanguage.values.asNameMap()[stored] ?? ReceiptLanguage.french;
  }

  Future<void> setLanguage(ReceiptLanguage language) async {
    state = language;
    await ref.read(sharedPreferencesProvider).setString(_key, language.name);
  }
}

final receiptLanguageProvider =
    NotifierProvider<ReceiptLanguageController, ReceiptLanguage>(
      ReceiptLanguageController.new,
    );