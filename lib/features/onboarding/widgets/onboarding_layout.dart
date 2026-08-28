import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/shared/widgets/brand_title.dart';

import 'onboarding_form.dart';
import 'onboarding_sidebar.dart';

/// Responsive shell for the onboarding screen.
///
/// - Compact (< 600dp): Brewline logo at top, form centered below
/// - Medium (600–905dp): Brewline logo in a branded header area, form in a card
/// - Expanded (≥ 905dp): two-pane — sidebar on left, form centered in remaining space
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _CompactBody(),
        tablet: _MediumBody(),
        desktop: _ExpandedBody(),
      ),
    );
  }
}

/// Compact mobile layout: Brewline logo at top, form below.
class _CompactBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // Brand header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: Space.x2l),
            child: Column(
              children: [
                Icon(
                  Icons.local_cafe_rounded,
                  size: 40,
                  color: colorScheme.primary,
                ),
                SizedBox(height: Space.sm),
                BrandTitle(),
                SizedBox(height: Space.xs),
                Text(
                  'Set up your café',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          // Form
          Expanded(child: OnboardingForm()),
        ],
      ),
    );
  }
}

/// Medium tablet layout: branded header + form in a card below.
class _MediumBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand header
            Padding(
              padding: EdgeInsets.symmetric(vertical: Space.x2l),
              child: Column(
                children: [
                  Icon(
                    Icons.local_cafe_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  SizedBox(height: Space.sm),
                  BrandTitle(),
                  SizedBox(height: Space.xs),
                  Text(
                    'Set up your café',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Form card
            Card(
              elevation: 0,
              clipBehavior: Clip.hardEdge,
              color: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Rounded.x3l),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              margin: EdgeInsets.symmetric(horizontal: Space.x2l),
              child: OnboardingForm(),
            ),
            SizedBox(height: Space.xl),
          ],
        ),
      ),
    );
  }
}

/// Desktop expanded layout: sidebar + form side by side.
class _ExpandedBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OnboardingSidebar(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440),
              child: OnboardingForm(),
            ),
          ),
        ),
      ],
    );
  }
}
