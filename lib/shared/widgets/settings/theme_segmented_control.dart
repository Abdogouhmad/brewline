import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Theme preference as a full-width [SegmentedButton] row — System / Light /
/// Dark read better as segments than inside a dropdown. On phones the leading
/// avatar and the per-segment icons are dropped so the control fits the
/// narrower settings card.
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
    final compact = Breakpoints.of(context) == ScreenSize.compact;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!compact) ...[
          Container(
            width: AppSizes.iconLg * 1.5,
            height: AppSizes.iconLg * 1.5,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(Rounded.xl),
            ),
            child: Icon(
              Icons.brightness_6_rounded,
              size: AppSizes.iconMd,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          SizedBox(width: Space.lg),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Space.lg),
              UiText(
                l10n.settingsThemeTitle,
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w600,
              ),
              UiText(
                l10n.settingsThemeSubtitle,
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
                        icon: compact
                            ? null
                            : Icon(_themeIcon(pref), size: AppSizes.iconSm + 2),
                        label: Text(switch (pref) {
                          ThemePref.system => l10n.settingsThemeSystem,
                          ThemePref.light => l10n.settingsThemeLight,
                          ThemePref.dark => l10n.settingsThemeDark,
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
