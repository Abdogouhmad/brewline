import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Language preference as a dropdown rendered in a settings tile's trailing
/// slot. Copies [localeControllerProvider] on change so the choice persists.
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

    return DropdownButtonHideUnderline(
      child: DropdownButton<AppLanguage>(
        value: value,
        borderRadius: BorderRadius.circular(Rounded.lg),
        padding: EdgeInsets.symmetric(horizontal: Space.sm),
        items: [
          for (final language in AppLanguage.values)
            DropdownMenuItem<AppLanguage>(
              value: language,
              child: UiText(
                language.label,
                type: UiTextType.labelLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
        icon: Icon(Icons.expand_more_rounded, color: colorScheme.primary),
      ),
    );
  }
}
