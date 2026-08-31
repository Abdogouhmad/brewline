# Refund System — Implementation Spec (Brewline / Café POS)

**Audience:** opencode coding agent
**Stack:** Flutter, Riverpod, `sqflite_common_ffi`
**Depends on:** `ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` (Sales Log screen, repository pattern, `audit_events`), `CASHOUT_PRINTING_SPEC.md` (`ReceiptPrinterService`, receipt templates). Read those first.
**Status:** Ready for implementation. Scope is deliberately narrowed to "fix a mistaken order," not general order editing — see §2.1.

---

## 0. Summary of Changes

1. A refund entry point inside the **Sales Log** row actions: admin can either **partially correct** (update) or **fully void** (delete/refund) a mistaken order.
2. A new `order_refunds` table — a real table, not derived, because it needs to be queryable, filterable, and printable on its own.
3. Reuses the fraud-detection `audit_events` signals that already exist for exactly this — `void` and `post_print_edit` — no new event types needed.
4. A responsive action UI: **dialog on desktop, bottom sheet on mobile/tablet.**
5. An optional refund receipt print showing the refunded amount as a negative figure.

---

## 1. Where This Lives

Entry point: a row action (icon button or overflow menu item) on each row of the Sales Log screen (`ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` §3) — "Refund." Tapping it opens the refund UI (§5) scoped to that one order.

---

## 2. Functionality

### 2.1 Scope constraint (read this first)
The request describes fixing a **mistaken order** — an overcharge or wrong item, not general order editing. To keep the feature from becoming an unaudited way to inflate revenue, both actions below can only ever **decrease** an order's total, never increase it:
- "Update" may reduce a line item's quantity or remove a line item entirely. It cannot add new items or increase quantities.
- If you actually want full bidirectional order editing (not just refund-oriented corrections), that's a bigger feature — flag it back rather than assuming this spec covers it.

### 2.2 "Update sale order" (partial refund)
- Admin opens the order's line items in edit mode, reduces a quantity or removes an item.
- The new total is recomputed live as they edit; the **refund amount = old total − new total** (always ≥ 0, given the §2.1 constraint).
- Reason field is **required** (short free text, e.g. "wrong item entered") — this is a financial adjustment, it needs a paper trail.
- On confirm: `order_items` is updated to the corrected quantities (the order itself now reflects the corrected state — this is a genuine correction, not just an annotation), and one row is written to `order_refunds` (§3) with `refund_type = 'partial'` and the computed amount.
- Logs an `audit_events` row with `event_type = 'post_print_edit'` (this signal already exists in the fraud-detection model — reuse it, don't add a new type) with metadata `{order_id, old_total, new_total, reason}`.

### 2.3 "Delete sale order" (full refund / void)
- Admin confirms voiding the entire order. Reason field required, same as above.
- The order is **not hard-deleted** from the database — historical financial records must stay intact for reporting and audit (same principle already applied to product deletion → soft archive in the admin dashboard spec). Instead:
  - `orders.is_voided` is set to `1` (new column, see §3).
  - One row is written to `order_refunds` with `refund_type = 'full'` and `amount_cents` equal to the order's full total.
- Logs an `audit_events` row with `event_type = 'void'` (also already an existing signal — reuse it) with metadata `{order_id, amount, reason}`.
- A voided order's items are left untouched in `order_items` — the void is expressed entirely through `orders.is_voided` + the `order_refunds` row, not by deleting line items.

---

## 3. Database

```sql
ALTER TABLE orders ADD COLUMN is_voided INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS order_refunds (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL REFERENCES orders(id),
  admin_id INTEGER NOT NULL REFERENCES users(id),
  refund_type TEXT NOT NULL CHECK (refund_type IN ('partial', 'full')),
  amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_order_refunds_order_id ON order_refunds(order_id);
CREATE INDEX IF NOT EXISTS idx_order_refunds_created_at ON order_refunds(created_at);
```

Why a dedicated table and not just an `audit_events` metadata blob: the same reasoning as `cashout_logs` — this needs to be summed, filtered by date, and displayed/printed as structured data (order id, amount, reason), not just counted as a fraud-signal flag. `audit_events` still gets its own row too (§2.2/§2.3) purely for the fraud-signal side — the two tables serve different purposes and neither substitutes for the other.

Repository: `lib/core/database/repositories/refund_repository.dart`
- `applyPartialRefund({required int orderId, required List<OrderItemAdjustment> adjustments, required String reason, required int adminId})` — runs the `order_items` update + `order_refunds` insert + `audit_events` insert in **one transaction**.
- `voidOrder({required int orderId, required String reason, required int adminId})` — same pattern: `orders.is_voided = 1` + `order_refunds` insert + `audit_events` insert, one transaction.
- `getRefundsForOrder(int orderId)` — used to show refund history on an order if it's been partially refunded more than once.

---

## 4. Cross-Cutting Impacts (don't skip this)

Once refunds exist, every place that sums "total sales" needs to account for them, or your numbers will be wrong:

- **Sales Log** (`sales_query_repository.dart`): join in refunded amounts per order (`LEFT JOIN` an aggregated `SUM(order_refunds.amount_cents) GROUP BY order_id`, using the index from §3) and display **net total** (original − refunded), plus a visible badge: "Refunded" (partial) or "Voided" (full) on affected rows. Excluded/adjusted consistently — don't just subtract silently with no visual indicator, the admin needs to see which rows were touched.
- **Dashboard summary cards / busiest-hours heatmap** (`ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` §6–7): these should reflect net revenue too — a voided order shouldn't count toward "today's sales" or inflate a busy-hour cell. Exclude `is_voided = 1` orders and subtract partial-refund amounts from whatever total-sales query currently powers them.
- **Cashout logs are immutable snapshots — do not retroactively edit them.** If a refund happens *after* a shift has already been cashed out (`cashout_logs` row already written), that historical row stays exactly as printed/recorded at the time — don't rewrite `cashout_logs.total_sales_cents` after the fact. The refund still gets recorded in `order_refunds` with its own timestamp; it just won't retroactively change a shift report that was already finalized and printed. This is a known, acceptable gap (real-world equivalent: a paper correction after the till was already closed) — flag back if you'd rather have cashout reports auto-adjust, but that would mean a "final" report isn't actually final, which undermines the point of §3.1 in the cashout spec.

---

## 5. UI — Responsive Refund Action

One shared widget picks its presentation by `ScreenSize` (`core/responsive/breakpoints.dart`, already established):

- **Expanded (desktop):** `showDialog` — a fixed-width (~480dp) M3 dialog.
- **Compact / Medium (mobile & tablet):** `showModalBottomSheet` — full-width, rounded top corners (28dp, consistent with the rest of the app's M3 Expressive corner radii), draggable to dismiss.

```
lib/features/reports/widgets/
  refund_action_sheet.dart   // picks Dialog vs BottomSheet by ScreenSize, hosts the shared form content
  order_refund_form.dart     // the actual form: order summary + edit/void toggle + reason field + confirm button
```

**`order_refund_form.dart` contents (same content, either shell):**
1. Read-only order summary at the top: order #, waiter name, date/time, current line items and total.
2. A segmented toggle: **"Correct Order"** (update) vs **"Void Order"** (full refund).
   - Correct Order mode: each line item gets a quantity stepper (can only go down) and a remove (×) action; running total updates live; a computed "Refund amount: $X.XX" is shown once anything's been changed.
   - Void Order mode: no line-item editing, just a summary confirming the full amount that will be refunded.
3. Reason field (`AppTextField`, required, non-empty) — shared field regardless of mode.
4. Confirm button label reflects the mode and amount: "Refund $X.XX" — disabled until the reason is filled and (in Correct Order mode) at least one change has been made.
5. On success: close the sheet/dialog, show a brief success confirmation, and offer the optional print action (§6).

---

## 6. Refund Receipt (optional)

If you want a printed record of the refund (the "-9" style report), add one more template reusing the existing printer plumbing from `CASHOUT_PRINTING_SPEC.md` — no new transport work needed.

```
lib/core/printing/receipt_templates/
  refund_receipt_template.dart   // 88mm, same width as the client receipt/report
```

Content: header (café name, same as other receipts) → "REFUND" label, bold/centered → order # → original total → refunded amount shown as a **negative figure** (e.g. `-$9.00`) → reason → admin name → timestamp. Print is **not automatic** — after a successful refund, show a "Print Refund Receipt" button in the success state (§5 step 5); admin decides whether it's needed, since not every till correction needs a paper copy.

---

## 7. Documentation Requirements

- `refund_repository.dart` documents why both refund actions are transactional (line-item update / void flag + `order_refunds` insert + `audit_events` insert must all succeed together or none should) and cross-references the §2.1 decrease-only constraint so a future change doesn't accidentally allow refunds to increase a total.
- Any query touched in §4 (Sales Log, dashboard totals, busiest-hours) gets a one-line comment noting it now excludes voided orders / nets out partial refunds, so the exclusion isn't silently reverted by an unrelated future edit.
- `refund_action_sheet.dart` documents the desktop-dialog / mobile-bottom-sheet split so it's clear that's intentional responsive behavior, not two divergent implementations.

---

## 8. Acceptance Checklist

- [ ] Refund entry point appears on each Sales Log row, opens the correct shell (dialog on desktop, bottom sheet on mobile/tablet) based on live screen width, not device type
- [ ] "Correct Order" can only reduce quantities or remove items — no path exists to increase a total through this feature
- [ ] Partial refund updates `order_items`, writes one `order_refunds` row (`partial`), and logs `post_print_edit` in `audit_events`
- [ ] Void sets `orders.is_voided = 1` without deleting the order or its items, writes one `order_refunds` row (`full`), and logs `void` in `audit_events`
- [ ] Reason field is required and enforced before the confirm button is enabled, in both modes
- [ ] Sales Log now shows a net total and a visible Refunded/Voided badge on affected rows
- [ ] Dashboard summary cards and the busiest-hours heatmap exclude voided orders and net out partial refunds
- [ ] Existing `cashout_logs` rows are never rewritten by a later refund — confirmed by refunding an order from an already-closed shift and checking the historical report is unchanged
- [ ] Optional refund receipt prints at 88mm with the refunded amount shown as negative, only when explicitly requested via the print button
- [ ] All refund writes go through `refund_repository.dart` — no ad hoc `order_items`/`orders` mutation elsewhere in the codebase for this feature
