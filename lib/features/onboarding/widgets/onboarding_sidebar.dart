import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/shared/widgets/brand_title.dart';

/// Desktop sidebar for the onboarding screen: brand identity on a
/// solid secondary-container background.
///
/// Fixed 360dp width, 28dp outer radius on the content-facing edge.
class OnboardingSidebar extends StatelessWidget {
  const OnboardingSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(Rounded.x3l),
          bottomRight: Radius.circular(Rounded.x3l),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Space.x2l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_cafe_rounded,
                size: 72,
                color: colorScheme.onSecondaryContainer,
              ),
              SizedBox(height: Space.xl),
              BrandTitle(
                showTagline: true,
              ),
              SizedBox(height: Space.lg),
              Text(
                'Set up your café\nin just a few steps.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer
                          .withValues(alpha: 0.8),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
