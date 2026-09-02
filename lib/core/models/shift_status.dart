/// The live shift status of a waiter, shown on the admin dashboard's shift
/// status card.
///
/// Derived from the `audit_events` log — there is no `shifts` table, matching
/// brewline's convention that shift state is derived, never stored.
enum ShiftState {
  /// Logged in and working.
  active,

  /// Logged out mid-shift (e.g. on a break, went to the toilet) — can resume
  /// by signing back in.
  idle,

  /// Shift closed out — the end of the shift, money counted and reported.
  cashedOut,

  /// No shift events recorded yet for this member.
  never,
}

extension ShiftStateLabel on ShiftState {
  String get label => switch (this) {
        ShiftState.active => 'Active',
        ShiftState.idle => 'Idle',
        ShiftState.cashedOut => 'Cashed out',
        ShiftState.never => 'No shift yet',
      };
}

/// Per-waiter shift snapshot.
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

  /// The member's current shift state (see [ShiftState]).
  final ShiftState state;

  const ShiftStatus({
    required this.name,
    required this.username,
    required this.checkIn,
    required this.lastCashOut,
    required this.state,
  });
}
