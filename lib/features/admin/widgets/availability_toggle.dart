import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// In-service toggle for a product card. Writes through
/// [productMutationProvider] so the waiter menu and dashboard stock alerts
/// update live from the same switch.
class AvailabilityToggle extends ConsumerWidget {
  final String productId;
  final bool available;

  const AvailabilityToggle({
    super.key,
    required this.productId,
    required this.available,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiText(
          available ? l10n.availabilityOnMenu : l10n.availabilitySoldOut,
          type: UiTextType.labelSmall,
          fontWeight: FontWeight.w600,
          color: available ? colorScheme.tertiary : colorScheme.outline,
        ),
        SizedBox(width: Space.xs),
        Switch(
          value: available,
          onChanged: (value) => ref
              .read(productMutationProvider.notifier)
              .setAvailable(productId, value),
        ),
      ],
    );
  }
}
