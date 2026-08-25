import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// Per-receipt printing switches shown in Settings → Printing.
class PrintingPreferences {
  final bool kitchenReceipt;
  final bool clientReceipt;

  const PrintingPreferences({
    required this.kitchenReceipt,
    required this.clientReceipt,
  });

  /// Both receipts on — the sensible default for a waiter terminal.
  static const defaults = PrintingPreferences(
    kitchenReceipt: true,
    clientReceipt: true,
  );

  PrintingPreferences copyWith({bool? kitchenReceipt, bool? clientReceipt}) =>
      PrintingPreferences(
        kitchenReceipt: kitchenReceipt ?? this.kitchenReceipt,
        clientReceipt: clientReceipt ?? this.clientReceipt,
      );
}

/// Persists each receipt toggle under its own key so order-flow code can
/// read a single flag without touching the other.
class PrintingPreferencesController
    extends Notifier<PrintingPreferences> {
  static const _kitchenKey = 'print_kitchen_receipt';
  static const _clientKey = 'print_client_receipt';

  @override
  PrintingPreferences build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return PrintingPreferences(
      kitchenReceipt:
          prefs.getBool(_kitchenKey) ?? PrintingPreferences.defaults.kitchenReceipt,
      clientReceipt:
          prefs.getBool(_clientKey) ?? PrintingPreferences.defaults.clientReceipt,
    );
  }

  Future<void> setKitchenReceipt(bool enabled) async {
    state = state.copyWith(kitchenReceipt: enabled);
    await ref.read(sharedPreferencesProvider).setBool(_kitchenKey, enabled);
  }

  Future<void> setClientReceipt(bool enabled) async {
    state = state.copyWith(clientReceipt: enabled);
    await ref.read(sharedPreferencesProvider).setBool(_clientKey, enabled);
  }
}

final printingPreferencesProvider =
    NotifierProvider<PrintingPreferencesController, PrintingPreferences>(
  PrintingPreferencesController.new,
);
