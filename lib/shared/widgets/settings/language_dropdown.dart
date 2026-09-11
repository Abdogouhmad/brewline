import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Working language preference control (English / Français / System default).
///
/// Persists the choice immediately through [languageControllerProvider] (no
/// separate save button, matching the other Settings toggles) and applies it
/// to [MaterialApp] via the `localeProvider` — the app re-renders on selection
/// without a restart.
class LanguageDropdown extends StatelessWidget {
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  const LanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Language names (English / Français) stay in their own language; the
    // "follow the OS" option is the only localizable label.
    String labelFor(AppLanguage language) => language == AppLanguage.system
        ? l10n.settingsLanguageSystemDefault
        : language.label;

    return PopupMenuButton<AppLanguage>(
      initialValue: value,
      tooltip: l10n.settingsLanguageChooseTooltip,
      onSelected: onChanged,
      color: colorScheme.surfaceContainer,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final language in AppLanguage.values)
          PopupMenuItem<AppLanguage>(
            value: language,
            child: Row(
              children: [
                Icon(
                  value == language
                      ? Icons.check_rounded
                      : Icons.translate_rounded,
                  size: AppSizes.iconSm,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: Space.sm),
                Text(labelFor(language)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(Rounded.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: AppSizes.iconSm,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: Space.xs),
            UiText(
              labelFor(value),
              type: UiTextType.labelMedium,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: AppSizes.iconSm,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}