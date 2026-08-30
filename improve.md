# Cashout & Report Printing — Implementation Spec (Brewline / Café POS)
 
**Audience:** opencode coding agent
**Stack:** Flutter, Riverpod, `sqflite_common_ffi`, `esc_pos_utils_plus`
**Depends on:** `ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` (repository pattern, `audit_events` table, Sales Log screen pattern), `LOGIN_UI_SPEC.md` (`authProvider.logout()`). Read those first.
**Status:** Ready for implementation. One deliberate deviation from the literal request is called out in §3 with reasoning — flag back if you'd rather I follow the literal version.
 
---
 
## 0. Summary of Changes
 
1. A `cashout_logs` table — a real, dedicated table (not a query/view) recording every finalized shift close, because it captures a point-in-time snapshot (counted cash, variance) that can't be derived from `orders` alone.
2. Waiter **Settings** page gets two actions: **"Cash Out & Print Report"** (closes the shift, logs waiter out) and **"Print Report"** (interim, no shift close, no logout).
3. Admin gets a **Cashout Logs** page mirroring the Sales Log pattern: Date/Time, Orders Made, Waiter Name, Total Made.
4. A printer transport layer supporting **both USB-cable and network (Ethernet/RJ45) printers** through one abstraction, plus three receipt templates at two paper widths (55mm kitchen, 88mm client/report).
---
 
## 1. Printer Connectivity (USB + Network)
 
### 1.1 Recommended packages
- **`esc_pos_utils_plus`** — already in the stack. Keep using it purely to *build* ESC/POS byte sequences (text, alignment, bold, cut, line feeds). It doesn't send anything over a wire; it just generates `List<int>` bytes.
- **Network (RJ45/Ethernet) transport → plain Dart `Socket`, no extra package needed.** Thermal printers with an Ethernet port almost universally listen for raw ESC/POS bytes on **TCP port 9100** (RAW/JetDirect-style printing). Dart's built-in `dart:io` `Socket.connect(ip, 9100)` + `socket.add(bytes)` is enough — it's simpler and more reliable than any plugin for this case, and it works identically on Android and desktop with zero native code.
- **USB transport → `flutter_pos_printer_platform_image_3`.** Unlike network printing, USB requires the Android USB Host API, which needs a native plugin — plain Dart sockets can't do this. This package already covers USB (and Bluetooth, unused here) through one plugin, so it's the right single dependency for the USB path. Drop `print_bluetooth_thermal` from the dependency list if it's still there — it only covers Bluetooth, which isn't needed for this feature, and having two overlapping printer plugins is exactly the kind of redundancy worth avoiding.
### 1.2 Transport abstraction
Keep printing transport-agnostic (matches this project's existing preference for transport-agnostic service interfaces) so receipt-building code never knows or cares whether it's USB or network:
 
```
lib/core/printing/
  printer_transport.dart            // abstract class PrinterTransport { Future<void> send(List<int> bytes); Future<bool> isConnected(); }
  network_printer_transport.dart    // implements PrinterTransport via Socket.connect(ip, 9100)
  usb_printer_transport.dart        // implements PrinterTransport via flutter_pos_printer_platform_image_3
  receipt_printer_service.dart      // builds bytes with esc_pos_utils_plus, sends via the configured PrinterTransport
```
- `receipt_printer_service.dart` reads the active transport type from printer settings (§1.3) at call time — callers just do `receiptPrinterService.printKitchenTicket(order)` etc. and never touch USB/network details directly.
- Wrap every `send()` call with a timeout (e.g. 5s) and a clear typed error (`PrinterOfflineException`, `PrinterTimeoutException`) so the UI can show "Printer not reachable" instead of hanging.
### 1.3 Printer settings (admin-configurable)
Add a small settings section (device-level, not per-waiter) since a printer is physically attached to one device:
- Connection type: `usb` | `network` (radio/segmented choice)
- If `network`: IP address field + port field (default `9100`, editable in case a printer uses a nonstandard port)
- Location: `lib/features/admin/settings/widgets/printer_settings_section.dart`, added to the same Settings page that now hosts logout (`ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` §5). Persist via a simple key-value settings table or `shared_preferences` — this is small enough that a new dedicated table isn't warranted.
**Assumption:** one printer handles all three receipt types (kitchen, client, report) sequentially. If you actually have two physical printers (e.g. a kitchen printer and a front-counter printer), this needs a second transport config — flag that back rather than assuming.
 
---
 
## 2. Receipt Widths & Templates
 
Three receipt types, two physical widths:
 
| Receipt | Width | Used for |
|---|---|---|
| Kitchen ticket | 55mm | Sent to kitchen on order creation (existing) |
| Client receipt | 88mm | Given to the customer (existing) |
| Shift report | 88mm | New — printed by both Settings buttons in §3 |
 
`esc_pos_utils_plus`'s built-in `PaperSize` enum only ships presets for **58mm** and **80mm** — there is no built-in 55mm/88mm preset. Since your rolls are 55mm and 88mm specifically, don't rely on the enum: set the `LINE_WIDTH` (characters-per-line) constant directly per template based on the *actual* printable character count for your printer/font combination, rather than assuming it matches the 58mm/80mm presets. This continues the plan already noted for this project (confirm paper width, adjust `LINE_WIDTH` accordingly) — verify the real character count against a physical test print before finalizing the constants; don't hardcode a guessed number.
 
```
lib/core/printing/receipt_templates/
  kitchen_ticket_template.dart   // 55mm — existing, unchanged by this spec
  client_receipt_template.dart   // 88mm — existing, unchanged by this spec
  shift_report_template.dart     // 88mm — NEW, see §2.1
```
 
### 2.1 Shift report template
Content, top to bottom:
1. Café name / header (reuse whatever header block the client receipt already uses, for visual consistency)
2. "SHIFT REPORT" label, bold/centered
3. Waiter name
4. Shift start time → end time (end time = "now" if this is an interim print, see §3.2)
5. Order count
6. Total sales (formatted from integer cents)
7. Cash counted (only on the final cash-out print, §3.1 — omit this line entirely on the interim print since there's nothing counted yet)
8. Cash variance = counted − expected (only on the final print, same reason)
9. Footer: print timestamp
10. If this is the **interim** print (§3.2): a clearly visible **"PREVIEW — SHIFT NOT CLOSED"** line near the top, so nobody mistakes it for the final record.
Build with the same single `.write()`-with-embedded-`\n` approach already established for receipt assembly on this project — not `.writeln()` — to avoid the ESC/POS collapse issue already documented.
 
---
 
## 3. Waiter Settings — Two Actions
 
### 3.1 "Cash Out & Print Report" (final, closes the shift)
1. Confirm dialog first — this is irreversible for the shift: *"Cash out and print report? This will close your shift and log you out."* / Cancel / Confirm.
2. Prompt for **cash counted** (a numeric entry — the physical cash counted in the drawer at end of shift).
3. Compute the shift summary: order count + total sales for this shift (query via the existing order/shift relationship), variance = counted − expected.
4. Write **one row** to `cashout_logs` (§4) — this is the authoritative, final record of the shift.
5. Log an `audit_events` row with `event_type = 'cashout'` (per `ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` §4) with the same metadata.
6. Mark the shift closed — following this project's existing convention that shift status is *derived*, this means setting whatever field the "closed" state is derived from (e.g. a `cashed_out_at` timestamp on the shift), not adding a separate status flag.
7. Print the shift report (§2.1, final variant, includes cash-counted/variance lines).
8. On print success, call `authProvider.logout()` (reuses the existing logout flow/confirm-free, since the user already confirmed the combined action in step 1 — don't double-confirm).
9. If printing fails (printer offline/timeout): still complete steps 3–6 (don't lose the cashout because the printer was unreachable), show a clear "Report saved, but printing failed — check the printer" message, and offer a retry-print action before logging out. Never block the actual cashout on printer availability.
### 3.2 "Print Report" (interim, no sign-out) — deviation from the literal request
The original request said to also store this action's data in `cashout_logs`. I'm recommending against that, with reasoning:
 
- The shift is still **open** when this button is pressed — there's no final cash-counted or variance figure yet, and the order count/total could still change before the real cash-out.
- Writing a row to `cashout_logs` every time a waiter previews the report would leave multiple rows per shift, only one of which (the final one) is actually authoritative — which would make the admin's Cashout Logs screen (§5) misleading (which row is the "real" total for that shift?).
- This project already has a fraud-detection signal for **reprint frequency** — an interim/preview report print is exactly that kind of event. So: this button logs an `audit_events` row with `event_type = 'report_print'` (add this to the check constraint alongside `login`/`logout`/`cashout` from the previous spec) instead of writing to `cashout_logs`.
If you actually want every preview print recorded in `cashout_logs` regardless, that's a one-line change (call the same `CashoutRepository.logCashout(...)` method here too) — just be aware it'll produce multiple rows per shift and the admin screen will need a way to tell "final" rows apart from "preview" ones (e.g. an `is_final` column) if you go that route.
 
Behavior:
1. No confirm dialog needed — non-destructive, doesn't close anything.
2. Compute the *current* shift summary the same way as §3.1 step 3, but there's no cash-counted input for this path.
3. Print the shift report (§2.1, interim variant — "PREVIEW" label, no cash-counted/variance lines).
4. Log the `audit_events` row (`report_print`) as described above.
5. No navigation change — waiter stays on the Settings page.
---
 
## 4. Database: `cashout_logs`
 
```sql
CREATE TABLE IF NOT EXISTS cashout_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  waiter_id INTEGER NOT NULL REFERENCES users(id),
  shift_id INTEGER NOT NULL REFERENCES shifts(id),
  shift_start TEXT NOT NULL,
  shift_end TEXT NOT NULL,
  order_count INTEGER NOT NULL,
  total_sales_cents INTEGER NOT NULL,
  cash_counted_cents INTEGER NOT NULL,
  cash_variance_cents INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
 
CREATE INDEX IF NOT EXISTS idx_cashout_logs_waiter_id ON cashout_logs(waiter_id);
CREATE INDEX IF NOT EXISTS idx_cashout_logs_created_at ON cashout_logs(created_at);
```
 
This is a genuine dedicated table, not a derived query — unlike the Sales Log (`ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` §3), it stores `cash_counted_cents`, which is manually entered by the waiter and has no other source of truth in the schema.
 
Also extend the `audit_events.event_type` check constraint from the previous spec to add `report_print`:
```sql
-- event_type now: 'void','discount','post_print_edit','cash_variance',
-- 'no_sale_open','reprint','off_hours','login','logout','cashout','report_print'
```
 
Repository: `lib/core/database/repositories/cashout_repository.dart`
- `logCashout(CashoutRecord record)` — the one write path for §3.1 step 4, inside a transaction alongside the shift-close update (step 6).
- `getCashoutLogs({DateTimeRange? dateRange, int? waiterId, int limit = 100, int offset = 0})` — powers the admin screen in §5, indexed on `created_at`/`waiter_id`.
- `getCurrentShiftSummary(int shiftId)` — read-only, used by both §3.1 and §3.2 to compute live order count/total without duplicating that query logic in two places.
---
 
## 5. Admin: Cashout Logs Page
 
- Location: `lib/features/admin/reports/cashout_logs_page.dart`, reachable from admin navigation alongside the Sales Log page.
- Same shape as the Sales Log screen (`ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` §3): filter controls (date range, waiter) above a `DataTable2` below.
- Columns exactly as requested: **Date & Time, Orders Made, Waiter Name, Total Made.** (Cash-counted/variance are stored but not required as visible columns here — reasonable to add as an expandable row detail later if you want it, not required now.)
- Backed by `CashoutRepository.getCashoutLogs(...)` — one row per finalized shift close.
- *(Optional, not required for this pass):* a "reprint" action per row that re-runs the shift-report template against the stored row's data and sends it through `ReceiptPrinterService` — natural follow-on given the printer plumbing this spec already builds, but flagged as optional so it doesn't silently expand scope.
---
 
## 6. File Structure (new/changed files)
 
```
lib/
  core/
    printing/
      printer_transport.dart
      network_printer_transport.dart
      usb_printer_transport.dart
      receipt_printer_service.dart
      receipt_templates/
        shift_report_template.dart
    database/
      repositories/
        cashout_repository.dart
  features/
    waiter/
      settings/
        widgets/
          cashout_button.dart
          print_report_button.dart
    admin/
      settings/
        widgets/
          printer_settings_section.dart
      reports/
        cashout_logs_page.dart
```
 
---
 
## 7. Documentation Requirements
 
- `receipt_printer_service.dart` gets a file-level comment explaining the transport-agnostic design and why network printing uses a raw socket while USB requires a plugin (§1.1) — so a future maintainer doesn't "simplify" by trying to force both through one package.
- `cashout_repository.dart`'s `logCashout()` documents that it's the **only** authoritative write path to `cashout_logs`, and cross-references §3.2's reasoning for why interim prints don't call it.
- `shift_report_template.dart` documents the LINE_WIDTH-vs-PaperSize-enum caveat from §2 so nobody "fixes" it back to the enum defaults later.
---
 
## 8. Acceptance Checklist
 
- [ ] Network printer prints correctly over a raw TCP socket to port 9100 (test against the existing escpresso emulator, then a real network printer)
- [ ] USB printer prints correctly via `flutter_pos_printer_platform_image_3` on Android
- [ ] Switching printer connection type in admin settings actually changes which transport is used, without app restart
- [ ] Kitchen ticket still prints at 55mm, client receipt and shift report both print at 88mm, with correctly measured (not guessed) `LINE_WIDTH` values
- [ ] "Cash Out & Print Report": prompts for cash counted, writes exactly one `cashout_logs` row, closes the shift (derived status reflects this), prints the final report, then logs out
- [ ] "Cash Out & Print Report" still completes the cashout and shift close even if the printer is unreachable, and surfaces a clear retry-print option
- [ ] "Print Report": prints an interim report labeled as a preview, does **not** write to `cashout_logs`, does **not** close the shift, does **not** log out, and logs a `report_print` audit event
- [ ] Admin Cashout Logs page shows exactly one row per finalized shift with the four requested columns, filterable by date and waiter
- [ ] No raw printer/socket code exists outside `core/printing/` — all call sites go through `ReceiptPrinterService`
 
