/// In-process app restart hook.
///
/// The backup/restore flow replaces the live database file; the restored data
/// must be loaded by a **fresh** widget + provider tree — never hot-swapped
/// under a running UI. On desktop the OTA updater achieves that by spawning a
/// new process; here a callback rebuilds the whole app (`runApp` with a fresh
/// [ProviderScope]) which is the portable equivalent that works identically on
/// Android, iOS, Windows and Linux, and survives the Windows file-lock hazard
/// because every database connection is closed *before* the file swap.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rebuilds the entire app against current state (replacing the running
/// [ProviderScope]). Overridden in `main()`.
typedef AppRestart = Future<void> Function();

final appRestartProvider = Provider<AppRestart>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});