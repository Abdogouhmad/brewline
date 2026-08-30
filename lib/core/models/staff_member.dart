/// A staff account that can sign in to the POS (currently always a waiter).
///
/// PINs are never stored in plain text — `pinHash` holds the SHA-256 digest
/// from [hashPin] and the repository never exposes or writes raw PINs.
class StaffMember {
  final String id;
  final String username;

  /// SHA-256 digest of the staff PIN (see `core/security/password_hash.dart`).
  final String pinHash;

  /// Display name shown in shift/performance views.
  final String name;

  /// Deactivated accounts can no longer sign in but keep their history.
  final bool active;

  final DateTime createdAt;

  const StaffMember({
    required this.id,
    required this.username,
    required this.pinHash,
    required this.name,
    this.active = true,
    required this.createdAt,
  });

  /// Column map for SQLite writes (see the `staff` schema).
  Map<String, Object?> toRow() => {
    'id': id,
    'username': username,
    'pin_hash': pinHash,
    'name': name,
    'active': active ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  /// Parses one row from the `staff` table.
  static StaffMember fromRow(Map<String, Object?> row) => StaffMember(
    id: row['id'] as String,
    username: row['username'] as String,
    pinHash: row['pin_hash'] as String,
    name: row['name'] as String? ?? row['username'] as String,
    active: (row['active'] as int? ?? 1) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at'] as int? ?? 0,
    ),
  );
}
