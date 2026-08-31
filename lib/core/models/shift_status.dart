/// Per-waiter shift snapshot shown on the admin dashboard's shift status card.
///
/// Derived from the `audit_events` log — there is no `shifts` table, matching
/// brewline's convention that shift state is derived, never stored. A waiter
/// is considered **on shift** when their most recent shift-related event is a
/// `login`, and their most recent `cashout` (if any) predates that login.
class ShiftStatus {
  /// Display name of the staff member (`staff.name`).
  final String name;

  /// POS username (`staff.username`, matches `audit_events.actor`).
  final String username;

  /// When this member last tapped in, or `null` if never logged in.
  final DateTime? checkIn;

  /// When the member's last shift ended (a `cashout`), or `null` if they are
  /// currently on shift (or have never closed a shift).
  final DateTime? lastCashOut;

  /// Whether the member is currently on shift (latest event is a `login`).
  final bool onShift;

  const ShiftStatus({
    required this.name,
    required this.username,
    required this.checkIn,
    required this.lastCashOut,
    required this.onShift,
  });
}
