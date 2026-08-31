import 'package:brewline/core/models/audit_event.dart';
import 'package:brewline/core/models/shift_status.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/features/admin/providers/shift_status_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// A waiter's shift status must reflect that a cashout (or logout) ends the
/// shift — even when an older login event exists in the log.
void main() {
  final member = StaffMember(
    id: 'staff-w1',
    username: 'waiter1',
    pinHash: 'x',
    name: 'Waiter One',
    createdAt: DateTime(2026, 8, 29),
  );

  AuditEvent ev(String type, int id, DateTime at) =>
      AuditEvent(id: id, eventType: type, actor: 'waiter1', createdAt: at);

  ShiftStatus derive(List<AuditEvent> events) => deriveShiftStatus(member, events);

  test('cashout ends the shift despite an earlier login', () {
    // Newest first in the database: cashout (id 2), login (id 1).
    final s = derive([
      ev('cashout', 2, DateTime(2026, 8, 29, 18)),
      ev('login', 1, DateTime(2026, 8, 29, 9)),
    ]);
    expect(s.onShift, isFalse);
    expect(s.checkIn, DateTime(2026, 8, 29, 9));
    expect(s.lastCashOut, DateTime(2026, 8, 29, 18));
  });

  test('logout after cashout still reads as end of shift', () {
    // The real cashout flow writes cashout then logout — newest first by id.
    final s = derive([
      ev('logout', 3, DateTime(2026, 8, 29, 18, 5)),
      ev('cashout', 2, DateTime(2026, 8, 29, 18)),
      ev('login', 1, DateTime(2026, 8, 29, 9)),
    ]);
    expect(s.onShift, isFalse);
    expect(s.checkIn, DateTime(2026, 8, 29, 9));
    expect(s.lastCashOut, DateTime(2026, 8, 29, 18));
  });

  test('an ongoing login after a prior-day cashout is still on shift', () {
    final s = derive([
      ev('login', 3, DateTime(2026, 8, 29, 8)),
      ev('cashout', 2, DateTime(2026, 8, 28, 18)),
      ev('login', 1, DateTime(2026, 8, 28, 9)),
    ]);
    expect(s.onShift, isTrue);
    expect(s.checkIn, DateTime(2026, 8, 29, 8));
    expect(s.lastCashOut, DateTime(2026, 8, 28, 18));
  });

  test('plain logout without a cashout also ends the shift', () {
    final s = derive([
      ev('logout', 2, DateTime(2026, 8, 29, 12)),
      ev('login', 1, DateTime(2026, 8, 29, 9)),
    ]);
    expect(s.onShift, isFalse);
    expect(s.checkIn, DateTime(2026, 8, 29, 9));
    expect(s.lastCashOut, isNull);
  });

  test('no recorded events is never on shift', () {
    final s = derive([]);
    expect(s.onShift, isFalse);
    expect(s.checkIn, isNull);
    expect(s.lastCashOut, isNull);
  });
}
