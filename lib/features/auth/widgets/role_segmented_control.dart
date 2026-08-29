import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/user_role.dart';

/// Two-segment Admin / Waiter role switch.
///
/// Styled once here so the Admin/Waiter choice reads consistently wherever it
/// appears. The selected segment uses `secondaryContainer` so it is visually
/// distinct from the primary "Log in" button — users shouldn't confuse
/// "pick a role" with "submit".
class RoleSegmentedControl extends StatelessWidget {
  final Role selected;
  final ValueChanged<Role> onChanged;

  const RoleSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<Role>(
      segments: [
        for (final role in Role.values)
          ButtonSegment(
            value: role,
            icon: Icon(role == Role.admin
                ? Icons.admin_panel_settings_outlined
                : Icons.room_service_outlined),
            label: Text(role.label),
          ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerHighest),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rounded.xl),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}
