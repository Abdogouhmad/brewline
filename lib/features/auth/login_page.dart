import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/features/admin/pages/admin_home_page.dart';
import 'package:brewline/features/waiter/pages/waiter_home_page.dart';
import 'package:brewline/widgets/shared/auth_screen_layout.dart';

import 'providers/auth_provider.dart';
import 'widgets/login_form.dart';

/// Entry screen after onboarding: PIN-only login that auto-routes to the
/// matching dashboard (Admin or Waiter) based on which user the PIN belongs to.
///
/// Reuses the shared [AuthScreenLayout] so it renders with the same branding
/// as onboarding. Once [authProvider] holds a non-null session (a successful
/// login), this page replaces itself with the matching dashboard so the back
/// button never returns here mid-session.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value;

    // Successful login -> replace this screen with the role's dashboard.
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => session.role == Role.admin
                ? const AdminHomePage()
                : const WaiterHomePage(),
          ),
        );
      });
    }

    return Scaffold(
      body: AuthScreenLayout(
        form: const LoginForm(),
        headerMessage: 'Welcome back',
      ),
    );
  }
}
