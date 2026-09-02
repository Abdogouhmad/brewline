/// Write/read access to the `order_refunds` ledger plus the two refund
/// mutations (partial correction and full void) that power the "fix a
/// mistaken order" flow.
///
/// ## Why both refund actions are transactional
/// `applyPartialRefund` and `voidOrder` each touch three writes that must all
/// succeed together or none should: the `order_items` correction /
/// `orders.is_voided` flag, the `order_refunds` row, and the `audit_events`
/// fraud signal. If only one landed, the financial record would contradict
/// the refund ledger (or vice versa), so each runs inside a single
/// `_db.transaction`.
///
/// ## The decrease-only constraint (§2.1 of improve.md)
/// This feature exists to correct a *mistaken* order — it must never become
/// an unaudited way to inflate revenue. `applyPartialRefund` enforces that
/// every `OrderItemAdjustment.newQuantity` is `<` the item's recorded
/// quantity (or `0` to remove the line), and `voidOrder` refunds exactly the
/// original order total. There is deliberately **no code path that increases
/// an order total through this repository** — do not add one without
/// revisiting §2.1.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/order_item_adjustment.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/models/order_refund.dart';

/// The end state of a successfully processed refund — enough for the UI to
/// confirm and offer a receipt print (§6).
class RefundResult {
  final int orderId;
  final int amountCents;
  final bool isFull;
  final DateTime at;

  const RefundResult({
    required this.orderId,
    required this.amountCents,
    required this.isFull,
    required this.at,
  });
}

class RefundRepository {
  final Database _db;

  const RefundRepository(this._db);

  /// Loads one order with its current line items (the source for the refund
  /// form's read-only summary and edit mode).
  Future<OrderRecord?> getOrder(int orderId) async {
    final orderRows = await _db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (orderRows.isEmpty) return null;
    final order = orderRows.first;

    final itemRows = await _db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );
    return OrderRecord(
      id: orderId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        order['created_at'] as int,
      ),
      orderNumber: (order['order_number'] as num).toInt(),
      waiterUsername: order['waiter_username'] as String?,
      total: (order['total'] as num).toDouble(),
      isVoided: (order['is_voided'] as num).toInt() != 0,
      items: [
        for (final row in itemRows)
          OrderLineItem(
            id: row['id'] as int,
            productId: row['product_id'] as String,
            name: row['name'] as String,
            quantity: (row['quantity'] as num).toInt(),
            unitPrice: (row['unit_price'] as num).toDouble(),
          ),
      ],
    );
  }

  /// Refund history for [orderId], oldest first — lets the UI show that an
  /// already-partially-refunded order has been adjusted more than once.
  Future<List<OrderRefund>> getRefundsForOrder(int orderId) async {
    final rows = await _db.query(
      'order_refunds',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );
    return rows.map(OrderRefund.fromRow).toList();
  }

  /// Applies a **partial refund**: corrects [order_items] quantities, writes
  /// one `order_refunds` (`partial`) row and logs the `post_print_edit` audit
  /// signal — all in one transaction.
  ///
  /// The refund amount is the sum of the line reductions
  /// (`old_total − new_total`). [adjustments] maps each `order_items.id` to
  /// its corrected (always reduced) quantity; every item is validated against
  /// the value currently stored so a stale the UI can never raise a total.
  Future<RefundResult> applyPartialRefund({
    required int orderId,
    required List<OrderItemAdjustment> adjustments,
    required String reason,
    required String adminId,
  }) async {
    assert(reason.trim().isNotEmpty, 'Reason is required for a partial refund');

    return _db.transaction((txn) async {
      final originalTotal = await _orderTotal(txn, orderId);
      var refundedCents = 0;

      for (final adjustment in adjustments) {
        final current = await _lineQuantity(txn, adjustment.orderItemId);
        if (current == null) {
          throw StateError('Line item ${adjustment.orderItemId} not found');
        }
        if (adjustment.newQuantity >= adjustment.originalQuantity) {
          throw StateError(
            'Refund correction must reduce quantity '
            '(line ${adjustment.orderItemId})',
          );
        }
        final perUnitCents = (adjustment.unitPrice * 100).round();
        final reduced = current - adjustment.newQuantity;
        refundedCents += reduced * perUnitCents;

        if (adjustment.newQuantity == 0) {
          await txn.delete(
            'order_items',
            where: 'id = ?',
            whereArgs: [adjustment.orderItemId],
          );
        } else {
          await txn.update(
            'order_items',
            {'quantity': adjustment.newQuantity},
            where: 'id = ?',
            whereArgs: [adjustment.orderItemId],
          );
        }
      }

      if (refundedCents <= 0) {
        throw StateError('Partial refund must remove at least one unit');
      }

      // NOTE: `orders.total` is deliberately NOT rewritten. It keeps the
      // original charged amount; the net figure is derived as
      // `total − refund` (see §4 of improve.md). The correction is expressed
      // entirely through the corrected `order_items` quantities + the
      // `order_refunds` row, so the dashboard net and the Sales Log (which
      // reads the corrected lines) agree without double-subtracting.

      final createdAt = DateTime.now();
      final refundId = await txn.insert('order_refunds', {
        'order_id': orderId,
        'admin_id': adminId,
        'refund_type': 'partial',
        'amount_cents': refundedCents,
        'reason': reason,
        'created_at': createdAt.millisecondsSinceEpoch,
      });
      await txn.insert('audit_events', {
        'event_type': 'post_print_edit',
        'actor': adminId,
        'metadata': jsonEncode({
          'order_id': orderId,
          'refund_id': refundId,
          'old_total': originalTotal,
          'new_total': originalTotal - refundedCents / 100,
          'reason': reason,
        }),
        'created_at': createdAt.millisecondsSinceEpoch,
      });

      return RefundResult(
        orderId: orderId,
        amountCents: refundedCents,
        isFull: false,
        at: createdAt,
      );
    });
  }

  /// Voids an entire order (**full refund**): sets `orders.is_voided = 1`,
  /// writes one `order_refunds` (`full`) row equal to the order's total and
  /// logs the `void` audit signal — all in one transaction.
  ///
  /// The order and its line items are **not deleted** — historical financial
  /// records stay intact for reporting and audit (the same soft-archive
  /// principle as product deletion); the void is expressed entirely through
  /// `orders.is_voided` and the `order_refunds` row.
  Future<RefundResult> voidOrder({
    required int orderId,
    required String reason,
    required String adminId,
  }) async {
    assert(reason.trim().isNotEmpty, 'Reason is required for a full refund');

    return _db.transaction((txn) async {
      final total = await _orderTotal(txn, orderId);
      final amountCents = (total * 100).round();

      await txn.update(
        'orders',
        {'is_voided': 1},
        where: 'id = ?',
        whereArgs: [orderId],
      );

      final createdAt = DateTime.now();
      final refundId = await txn.insert('order_refunds', {
        'order_id': orderId,
        'admin_id': adminId,
        'refund_type': 'full',
        'amount_cents': amountCents,
        'reason': reason,
        'created_at': createdAt.millisecondsSinceEpoch,
      });
      await txn.insert('audit_events', {
        'event_type': 'void',
        'actor': adminId,
        'metadata': jsonEncode({
          'order_id': orderId,
          'refund_id': refundId,
          'amount': total,
          'reason': reason,
        }),
        'created_at': createdAt.millisecondsSinceEpoch,
      });

      return RefundResult(
        orderId: orderId,
        amountCents: amountCents,
        isFull: true,
        at: createdAt,
      );
    });
  }

  Future<double> _orderTotal(DatabaseExecutor txn, int orderId) async {
    final rows = await txn.query(
      'orders',
      columns: ['total'],
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Order $orderId not found');
    }
    return (rows.first['total'] as num).toDouble();
  }

  Future<int?> _lineQuantity(DatabaseExecutor txn, int lineId) async {
    final rows = await txn.query(
      'order_items',
      columns: ['quantity'],
      where: 'id = ?',
      whereArgs: [lineId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['quantity'] as num).toInt();
  }
}

final refundRepositoryProvider = FutureProvider<RefundRepository>(
  (ref) async =>
      RefundRepository(await ref.watch(appDatabaseProvider.future)),
);
