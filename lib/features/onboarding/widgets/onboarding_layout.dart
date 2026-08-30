import 'package:flutter/material.dart';

import 'package:brewline/widgets/shared/auth_screen_layout.dart';

import 'onboarding_form.dart';

/// Responsive shell for the onboarding screen.
///
/// Thin wrapper around the shared [AuthScreenLayout] that plugs in the
/// [OnboardingForm] and onboarding-specific header copy. Branding and the
/// compact / medium / expanded breakpoints live in the shared widget so the
/// login screen renders with the same visual treatment.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthScreenLayout(
        form: const OnboardingForm(),
        headerMessage: 'Set up your café',
      ),
    );
  }
}
