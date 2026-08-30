import 'dart:io';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Verifies the documented v1 → v2 upgrade ([kMigrations]): a database that
/// was created at version 1 (schema without `is_archived` / `order_number` /
/// `order_counters` / `audit_events`) opens at version 2 with all its data
/// intact and the new features usable.
void main() {
  sqfliteFfiInit();

  test('v1 database upgrades to v2 without losing data', () async {
    final dir = await Directory.systemTemp.createTemp('brewline_migrate_');
    final path = p.join(dir.path, 'brewline.db');
    addTearDown(() => dir.delete(recursive: true));

    // --- create the historic v1 schema ---
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE products (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              price REAL NOT NULL,
              image_path TEXT NOT NULL,
              category TEXT NOT NULL DEFAULT '',
              available INTEGER NOT NULL DEFAULT 1,
              stock_quantity INTEGER NOT NULL DEFAULT 0,
              low_stock_threshold INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE orders (
              id INTEGER PRIMARY KEY,
              created_at INTEGER NOT NULL,
              waiter_username TEXT,
              total REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE order_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
              product_id TEXT NOT NULL,
              name TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              unit_price REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE staff (
              id TEXT PRIMARY KEY,
              username TEXT NOT NULL UNIQUE,
              pin_hash TEXT NOT NULL,
              name TEXT NOT NULL,
              active INTEGER NOT NULL DEFAULT 1,
              created_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    await v1.insert('products', {
      'id': 'p-001',
      'name': 'Espresso',
      'price': 9.0,
      'image_path': 'assets/stack_imgs/expresso.jpg',
      'category': 'Coffee',
    });
    await v1.insert('orders', {
      'id': 1,
      'created_at': DateTime(2026, 8, 28, 10).millisecondsSinceEpoch,
      'waiter_username': null,
      'total': 9.0,
    });
    await v1.insert('order_items', {
      'order_id': 1,
      'product_id': 'p-001',
      'name': 'Espresso',
      'quantity': 1,
      'unit_price': 9.0,
    });
    await v1.close();

    // --- reopen through the normal open path → triggers 1→2 upgrade ---
    final db2 = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    addTearDown(() => db2.close());

    expect(await db2.getVersion(), 2);
    await db2.rawQuery('SELECT is_archived FROM products'); // column now exists
    await db2.rawQuery('SELECT order_number FROM orders'); // column now exists

    // Existing rows were not touched by the upgrade.
    final products = ProductRepository(db2);
    final kept = await products.byId('p-001');
    expect(kept?.name, 'Espresso');
    expect(kept?.isArchived, isFalse);

    // New features work end-to-end on the upgraded database.
    await products.archive('p-001');
    expect((await products.byId('p-001'))?.isArchived, isTrue);

    final journal = OrderJournalRepository(db2);
    final saved = await journal.addOrder(
      OrderRecord(
        id: 2,
        createdAt: DateTime(2026, 8, 29, 12),
        total: 9,
        items: const [
          OrderLineItem(
            productId: 'p-001',
            name: 'Espresso',
            quantity: 1,
            unitPrice: 9,
          ),
        ],
      ),
    );
    expect(saved.orderNumber, 1); // counter starts fresh

    final audit = AuditRepository(db2);
    await audit.logEvent(eventType: 'login', actor: 'admin');
    expect(await audit.recent(), hasLength(1));
  });
}
