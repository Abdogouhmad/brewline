import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/core/repositories/staff_repository.dart';

import 'auth_provider.dart';

/// The signed-in user's profile — the single source of truth for who's on
/// shift.
///
/// Bound to the live [authProvider] session: admins always display their
/// stored admin username; waiters are joined against the `staff` SQLite table
/// so the display name set up in the admin Staff tab shows up in the waiter
/// top bar and settings hero.
class UserProfile {
  final String id;
  final String username;
  final String name;
  final String role;

  const UserProfile({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Resolves to the signed-in user's profile, or `null` while logged out.
///
/// Admin → the username stored at onboarding. Waiter → the `staff` row joined
/// by the session's username (falling back to the username when the account
/// has no display name yet).
final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final session = ref.watch(authProvider).value;
  if (session == null) return null;

  if (session.role == Role.admin) {
    return UserProfile(
      id: session.userId,
      username: session.username,
      name: session.username,
      role: Role.admin.label,
    );
  }

  final staff = await ref.watch(staffRepositoryProvider.future);
  final member = await staff.byUsername(session.username);
  return UserProfile(
    id: session.userId,
    username: session.username,
    name: (member != null && member.name.isNotEmpty)
        ? member.name
        : session.username,
    role: Role.waiter.label,
  );
});
