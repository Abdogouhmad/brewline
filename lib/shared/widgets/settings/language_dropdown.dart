import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Placeholder for the (not yet wired) language preference.
///
/// The stored `AppLanguage` choice used to be presented as an interactive
/// dropdown, but [localeControllerProvider] is not connected to `MaterialApp`
/// yet (no `.arb`/Intl delegate), so switching the dropdown had zero visual
/// effect. It is rendered as a muted, disabled "Coming soon" label until
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

    // Render the actual dropdown the moment `MaterialApp.locale` follows
    // [localeControllerProvider]. Until then: a disabled reminder in the
    // tile's trailing slot (avoids removing the tile entirely from two
    // settings pages).
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(Rounded.lg),
      ),
      child: UiText(
        '${value.label} · Coming soon',
        type: UiTextType.labelMedium,
        color: colorScheme.outline,
      ),
    );
  }
}
