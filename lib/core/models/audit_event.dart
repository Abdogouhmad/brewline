/// One row of the `audit_events` session/money log.
///
/// Every login, logout and completed cashout writes a row with the event type,
/// the account that triggered it [(actor], the account's username or
/// `'admin'`) and an optional small JSON blob in [metadata] (e.g. cashout
/// totals). Written by [AuditRepository]; nothing else touches the table.
class AuditEvent {
  final int id;

  /// One of `login`, `logout`, `cashout` (see the table CHECK constraint).
  final String eventType;

  /// Username of the account that caused the event (`'admin'` for the admin
  /// account, a `staff` username for waiters).
  final String actor;

  /// Optional small JSON blob with event-specific detail (e.g. cashout totals).
  final String? metadata;

  final DateTime createdAt;

  const AuditEvent({
    required this.id,
    required this.eventType,
    required this.actor,
    this.metadata,
    required this.createdAt,
  });

  /// Parses one row from the `audit_events` table.
  static AuditEvent fromRow(Map<String, Object?> row) => AuditEvent(
    id: row['id'] as int,
    eventType: row['event_type'] as String,
    actor: row['actor'] as String,
    metadata: row['metadata'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );
}
