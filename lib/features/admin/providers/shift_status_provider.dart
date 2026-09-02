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
/// * Latest event is a `login` → **active**; check-in = that login time,
///   last cash out = the most recent `cashout` before it.
/// * Latest event is a `cashout` → **cashed out**; the shift is closed.
/// * Latest event is a `logout` → **idle** if the most recent `login` has no
///   closing `cashout` after it (a mid-shift break), otherwise **cashed out**
///   (the real cashout flow logs a logout after closing).
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
  if (eventList.isEmpty) {
    return ShiftStatus(
      name: member.name,
      username: member.username,
      checkIn: null,
      lastCashOut: null,
      state: ShiftState.never,
    );
  }

  // Events arrive newest first (id 1 = oldest, id N = newest).
  final latest = eventList.first.eventType;

  // Most recent login and cashout, scanning the newest-first list until each
  // is found. These bound the current (or last) shift window.
  DateTime? checkIn;
  DateTime? lastCashOut;
  for (final event in eventList) {
    if (event.eventType == 'login' && checkIn == null) {
      checkIn = event.createdAt;
    } else if (event.eventType == 'cashout' && lastCashOut == null) {
      lastCashOut = event.createdAt;
    }
    if (checkIn != null && lastCashOut != null) break;
  }

  // State from the newest event:
  //  * login → active (signed in and working)
  //  * cashout → cashed out (shift closed)
  //  * logout → idle if the current shift was never closed, cashed out if the
  //    closing cashout actually happened (the cashout flow emits a trailing
  //    logout after closing).
  late final ShiftState state;
  switch (latest) {
    case 'login':
      state = ShiftState.active;
    case 'cashout':
      state = ShiftState.cashedOut;
    case 'logout':
      final shiftClosedSinceLastLogin =
          lastCashOut != null && (checkIn == null || lastCashOut.isAfter(checkIn));
      state = shiftClosedSinceLastLogin ? ShiftState.cashedOut : ShiftState.idle;
    default:
      // Ignore non shift-defining events (report_print, void, ...) by falling
      // back to the previous relevant event.
      state = ShiftState.never;
  }

  return ShiftStatus(
    name: member.name,
    username: member.username,
    checkIn: checkIn,
    lastCashOut: lastCashOut,
    state: state,
  );
}
