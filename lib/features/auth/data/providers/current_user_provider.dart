import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's profile. Auth-domain state shared across features
/// (waiter, admin) that need to know who's on shift.
class UserProfile {
  final String id;
  final String name;
  final String role;

  const UserProfile({
    required this.id,
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

/// TODO: bind to database / auth once available.
final currentUserProvider = Provider<UserProfile>((ref) {
  return const UserProfile(id: 'u-001', name: 'John Doe', role: 'waiter');
});
