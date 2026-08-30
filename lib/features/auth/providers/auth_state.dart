import 'package:brewline/core/models/user_role.dart';

/// The authenticated session for a signed-in user.
///
/// A `null` session (the provider's value) means "logged out". When present,
/// it records the [role], the storage [userId] and the [username] the user
/// signed in with. Both dashboards read this to know who is on shift.
class AuthState {
  final Role role;
  final String userId;
  final String username;

  const AuthState({
    required this.role,
    required this.userId,
    required this.username,
  });
}
