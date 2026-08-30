import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Theme preference as a full-width [SegmentedButton] row — System / Light /
/// Dark read better as segments than inside a dropdown.
class ThemeSegmentedControl extends StatelessWidget {
  final ThemePref themePref;
  final ValueChanged<ThemePref> onChanged;

  const ThemeSegmentedControl({
    super.key,
    required this.themePref,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: AppSizes.iconMd / 2 + 2,
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          child: Icon(Icons.brightness_6_rounded, size: AppSizes.iconSm + 4),
        ),
        SizedBox(width: Space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(
                'Theme',
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w600,
              ),
              UiText(
                'Match your light / dark preference',
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: Space.md),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemePref>(
                  selected: {themePref},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => onChanged(selection.first),
                  segments: [
                    for (final pref in ThemePref.values)
                      ButtonSegment(
                        value: pref,
                        icon: Icon(_themeIcon(pref), size: AppSizes.iconSm + 2),
                        label: Text(switch (pref) {
                          ThemePref.system => 'System',
                          ThemePref.light => 'Light',
                          ThemePref.dark => 'Dark',
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _themeIcon(ThemePref pref) => switch (pref) {
    ThemePref.system => Icons.brightness_auto_rounded,
    ThemePref.light => Icons.light_mode_outlined,
    ThemePref.dark => Icons.dark_mode_outlined,
  };
}
