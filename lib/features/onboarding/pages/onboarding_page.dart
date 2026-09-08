import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/features/admin/pages/admin_home_page.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/features/onboarding/widgets/onboarding_layout.dart';

/// One-time setup screen shown only when no admin account exists yet.
///
/// Watches [onboardingCompleteProvider]; once the flag flips to true
/// (after a successful submit), navigates to the admin dashboard.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Once onboarding completes, navigate away. `ref.listen` fires exactly once
    // on the transition (unlike `addPostFrameCallback` in build, which can
    // double-navigate when the frame is pending through multiple rebuilds).
    ref.listen<bool>(onboardingCompleteProvider, (previous, complete) {
      if (!complete) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
    });

    return const OnboardingLayout();
  }
}
