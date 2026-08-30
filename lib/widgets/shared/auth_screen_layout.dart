import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/shared/widgets/brand_title.dart';

/// Generic responsive shell shared by the onboarding and login screens.
///
/// Keeps the two auth screens looking like the same app by centralising the
/// branding and breakpoint logic that used to live in each screen's private
/// layout:
///
/// - Compact (< 600dp): brand header on top, [form] below a divider
/// - Medium (600–905dp): brand header above [form] inside a card
/// - Expanded (≥ 905dp): two-pane — branded sidebar + centered [form]
class AuthScreenLayout extends StatelessWidget {
  /// The form widget to display (e.g. `OnboardingForm` or `LoginForm`).
  final Widget form;

  /// Short caption under the wordmark ("Set up your café", "Welcome back").
  final String headerMessage;

  const AuthScreenLayout({
    super.key,
    required this.form,
    required this.headerMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _CompactBody(form: form, headerMessage: headerMessage),
      tablet: _MediumBody(form: form, headerMessage: headerMessage),
      desktop: _ExpandedBody(form: form, headerMessage: headerMessage),
    );
  }
}

/// Brand mark (icon + wordmark + caption) used at the top of the compact
/// and medium layouts.
class _BrandHeader extends StatelessWidget {
  final String message;

  const _BrandHeader({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.local_cafe_rounded, size: 40, color: colorScheme.primary),
        SizedBox(height: Space.sm),
        const BrandTitle(),
        SizedBox(height: Space.xs),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Compact mobile layout: brand header at top, form below a divider.
class _CompactBody extends StatelessWidget {
  final Widget form;
  final String headerMessage;

  const _CompactBody({required this.form, required this.headerMessage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: Space.x2l),
            child: _BrandHeader(message: headerMessage),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(child: form),
        ],
      ),
    );
  }
}

/// Medium tablet layout: brand header above the form inside a card.
///
/// Wrapped in a scroll view so tall forms (e.g. login with its role switch)
/// never overflow on short viewports; when the content fits it stays centred.
class _MediumBody extends StatelessWidget {
  final Widget form;
  final String headerMessage;

  const _MediumBody({required this.form, required this.headerMessage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    const BrandTitle(),
                    SizedBox(height: Space.xs),
                    Text(
                      headerMessage,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 0,
                clipBehavior: Clip.hardEdge,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rounded.x3l),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                margin: EdgeInsets.symmetric(horizontal: Space.x2l),
                child: form,
              ),
              SizedBox(height: Space.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop expanded layout: branded sidebar + centered form.
class _ExpandedBody extends ConsumerWidget {
  final Widget form;
  final String headerMessage;

  const _ExpandedBody({required this.form, required this.headerMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
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
                  const BrandTitle(showTagline: true),
                  SizedBox(height: Space.lg),
                  Text(
                    headerMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Space.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: form,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
