import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Placeholder for the (not yet wired) language preference.
///
/// The stored `AppLanguage` choice used to be presented as an interactive
/// dropdown, but [localeControllerProvider] is not connected to `MaterialApp`
/// yet (no `.arb`/Intl delegate), so switching the dropdown had zero visual
/// effect. It is rendered as a muted, disabled "Coming soon" chip until
/// localization lands — an honest placeholder instead of a control that lies.
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

    return Container(
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
            Icons.translate_rounded,
            size: AppSizes.iconSm,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: Space.xs),
          UiText(
            '${value.label} · Coming soon',
            type: UiTextType.labelMedium,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}