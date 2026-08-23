import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';

/// Placeholder onboarding where the admin sets username, password
/// and confirm password. Shown only on first launch.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome to brewline',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Set up your admin account to get started.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.xl),
                const TextField(
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: Space.md),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: Space.md),
                const TextField(
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: 'Confirm password'),
                ),
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
