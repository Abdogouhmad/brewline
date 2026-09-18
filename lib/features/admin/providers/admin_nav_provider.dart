/// Shared selected-tab state for the admin shell.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the selected admin destination (Dashboard / Reports / Menu / ...).
///
/// Kept in a provider — not a widget-local notifier — so [AppShell]'s nav
/// chrome, the dashboard quick actions and any future deep-link all read and
/// write one source of truth. The `ValueNotifier` bridges Riverpod with the
/// shell's `ValueListenableBuilder`; it is disposed with the provider.
final adminNavIndexProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});