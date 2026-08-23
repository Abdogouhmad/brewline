import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/theme/theme_controller.dart';

/// Cycles through system → light → dark. Drop into any app bar or rail.
class ThemeToggleButton extends ConsumerWidget {
  final Widget? child;

  const ThemeToggleButton({super.key, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themeControllerProvider);

    return IconButton(
      tooltip: 'Theme: ${themePref.name}',
      onPressed: () => ref.read(themeControllerProvider.notifier).cycle(),
      icon: Icon(switch (themePref) {
        ThemePref.system => Icons.brightness_auto,
        ThemePref.light => Icons.light_mode,
        ThemePref.dark => Icons.dark_mode,
      }),
    );
  }
}
