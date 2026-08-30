/// A live (derived) snapshot of a waiter's current shift.
///
/// There is **no `shifts` table** in brewline — a waiter's shift is derived,
/// the same way "who's on shift" and shift close are derived elsewhere in the
/// app:
///
/// * **Start** — the waiter's most recent `login` audit event; if the account
///   has no recorded login (seed/historical data) it falls back to the start
///   of the current local day ("the shift is today so far").
/// * **Orders + total** — every `orders` row attributed to that waiter inside
///   `[shiftStart, shiftEnd)`.
///
/// Used by both waiter-facing actions ("Cash out & print report" and the
/// interim "Print report") so the two call sites never duplicate the query.
class ShiftSummary {
  /// Waiter the summary was computed for (matches `orders.waiter_username`).
  final String waiterUsername;

  /// Start of the current shift (see the class doc for derivation).
  final DateTime shiftStart;

  /// End of the window — now for a live summary, close time for a cashout.
  final DateTime shiftEnd;

  final int orderCount;

  /// Gross sales in integer cents (`orders.total` is REAL; converted × 100).
  final int totalSalesCents;

  const ShiftSummary({
    required this.waiterUsername,
    required this.shiftStart,
    required this.shiftEnd,
    required this.orderCount,
    required this.totalSalesCents,
  });
}