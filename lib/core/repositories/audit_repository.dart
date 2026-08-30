/// Write/read access to the `audit_events` session log.
///
/// One lean table, five event types: `login`, `logout`, `cashout`,
/// `report_print`, `password_changed` (the CHECK constraint keeps typos out).
/// Appended to by the auth flow, account updates, the final cashout and the
/// interim shift-report print; read by the (future) admin audit view and
/// fraud signals. Nothing else should touch the table — route every
/// session/money event through [logEvent] so the stream stays consistent.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/audit_event.dart';

class AuditRepository {
  final Database _db;

  const AuditRepository(this._db);

  /// Allowed [eventType] values (mirrors the table CHECK constraint).
  static const Set<String> kEventTypes = {
    'login',
    'logout',
    'cashout',
    'report_print',
    'password_changed',
  };

  /// Appends one row to the log.
  ///
  /// [actor] is the triggering username (`'admin'` or a `staff` username) and
  /// [metadata] is an optional small JSON blob with per-event detail (e.g.
  /// cashout totals). Uses the `id` primary key; lookups by the [actor] index.
  Future<void> logEvent({
    required String eventType,
    required String actor,
    String? metadata,
    DateTime? at,
  }) async {
    assert(kEventTypes.contains(eventType), 'Unknown event type: $eventType');
    await _db.insert('audit_events', {
      'event_type': eventType,
      'actor': actor,
      'metadata': metadata,
      'created_at': (at ?? DateTime.now()).millisecondsSinceEpoch,
    });
  }

  /// The most recent events, newest first, capped at [limit].
  ///
  /// Ordered by `id` (insertion order — monotonic PKs beat `created_at`
  /// whenever the clock jumps). Reads ride `idx_audit_events_actor` only when
  /// filtering by [actor].
  Future<List<AuditEvent>> recent({String? actor, int limit = 100}) async {
    final rows = await _db.query(
      'audit_events',
      where: actor == null ? null : 'actor = ?',
      whereArgs: actor == null ? null : [actor],
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(AuditEvent.fromRow).toList();
  }

  /// The most recent `login` event for [actor], or `null` if the account has
  /// never logged in.
  ///
  /// There is no `shifts` table, so this is how a waiter's current shift
  /// start is derived (see [CashoutRepository.currentShiftSummary]).
  Future<DateTime?> latestLogin(String actor) async {
    final rows = await _db.query(
      'audit_events',
      where: "event_type = 'login' AND actor = ?",
      whereArgs: [actor],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      rows.first['created_at'] as int,
    );
  }
}

final auditRepositoryProvider = FutureProvider<AuditRepository>(
  (ref) async => AuditRepository(await ref.watch(appDatabaseProvider.future)),
);
