import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/audit_event.dart';
import 'package:brewline/core/models/shift_status.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';

/// Per-waiter shift status for the admin dashboard shift status card.
///
/// Derives each staff member's current shift from the `audit_events` log —
/// there is no `shifts` table. For every waiter, the latest shift-defining
/// event (`login`/`logout`/`cashout`) decides their state:
///
/// * Latest event is a `login` → **on shift**; check-in = that login time,
///   last cash out = the most recent `cashout` before it.
/// * Latest event is a `cashout` or `logout` → **off shift**; check-in = the
///   most recent `login`, last cash out = the `cashout` (or `null` if they
///   merely logged out without closing).
///
/// Staff with no recorded events show as never on shift.
final shiftStatusProvider = FutureProvider<List<ShiftStatus>>((ref) async {
  // Recompute when the (admin) session or the staff roster changes.
  ref.watch(authProvider);
  ref.watch(staffMutationProvider);

  final audit = await ref.watch(auditRepositoryProvider.future);
  final staff = await ref.watch(staffListProvider.future);
  final events = await audit.shiftEvents();

  return staff
      .map(
        (member) =>
            deriveShiftStatus(member, events[member.username] ?? const <AuditEvent>[]),
      )
      .toList(growable: false);
});

/// Turns one member's event list (newest first) into a [ShiftStatus].
///
/// Extracted as a pure function (no DB/Riverpod) so it can be unit-tested in
/// isolation. See [shiftStatusProvider] for the derivation rules.
ShiftStatus deriveShiftStatus(
  StaffMember member,
  List<AuditEvent> eventList,
) {
  DateTime? checkIn;
  DateTime? lastCashOut;
  var onShift = false;

  // The newest event alone settles the *current* state — a cashout or logout
  // always ends the shift, regardless of how far back a login appears. We then
  // scan for the most recent login and cashout to bound the (current or last)
  // shift window.
  for (var i = 0; i < eventList.length; i++) {
    final event = eventList[i];
    if (i == 0) {
      onShift = event.eventType == 'login';
    }
    if (event.eventType == 'login' && checkIn == null) {
      checkIn = event.createdAt;
    } else if (event.eventType == 'cashout' && lastCashOut == null) {
      lastCashOut = event.createdAt;
    }
  }

  return ShiftStatus(
    name: member.name,
    username: member.username,
    checkIn: checkIn,
    lastCashOut: lastCashOut,
    onShift: onShift,
  );
}
