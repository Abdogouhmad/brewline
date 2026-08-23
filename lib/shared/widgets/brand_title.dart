import 'package:flutter/material.dart';

import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Brand identity wordmark for app bars and splash surfaces.
/// Scales font size by device type; "Line" carries the primary color.
class BrandTitle extends StatelessWidget {
  final bool showTagline;

  const BrandTitle({super.key, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = responsiveValue(
      context,
      mobile: 18.0,
      tablet: 22.0,
      desktop: 24.0,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.local_cafe_rounded,
          size: fontSize + 4,
          color: colorScheme.primary,
        ),
        SizedBox(width: responsiveValue(context, mobile: 6.0, desktop: 10.0)),
        UiText(
          'Brew',
          type: UiTextType.headlineMedium,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        UiText(
          'Line',
          type: UiTextType.headlineMedium,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: colorScheme.primary,
        ),
        if (showTagline) ...[
          SizedBox(width: 10),
          UiText(
            'for waiters',
            type: UiTextType.labelLarge,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}
