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

  test('v1 database upgrades without losing data (ends at current schema v3)',
    () async {
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

    expect(await db2.getVersion(), 3);
    await db2.rawQuery('SELECT is_archived FROM products'); // column now exists
    await db2.rawQuery('SELECT order_number FROM orders'); // column now exists
    await db2.rawQuery('SELECT * FROM cashout_logs'); // table now exists

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

  test('v2 database upgrades to v3: cashout_logs + widened audit CHECK', () async {
    final dir = await Directory.systemTemp.createTemp('brewline_migrate_');
    final path = p.join(dir.path, 'brewline.db');
    addTearDown(() => dir.delete(recursive: true));

    // --- create the historic v2 schema (is_archived, order_number,
    // order_counters, audit_events with the ORIGINAL login/logout/cashout
    // CHECK) ---
    final v2 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE products (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, price REAL NOT NULL,
              image_path TEXT NOT NULL, category TEXT NOT NULL DEFAULT '',
              available INTEGER NOT NULL DEFAULT 1,
              stock_quantity INTEGER NOT NULL DEFAULT 0,
              low_stock_threshold INTEGER NOT NULL DEFAULT 0,
              is_archived INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE orders (
              id INTEGER PRIMARY KEY, created_at INTEGER NOT NULL,
              waiter_username TEXT, total REAL NOT NULL,
              order_number INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE order_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
              product_id TEXT NOT NULL, name TEXT NOT NULL,
              quantity INTEGER NOT NULL, unit_price REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE staff (
              id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE,
              pin_hash TEXT NOT NULL, name TEXT NOT NULL,
              active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE order_counters (
              date TEXT PRIMARY KEY, last_number INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE audit_events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              event_type TEXT NOT NULL CHECK (event_type IN ('login', 'logout', 'cashout')),
              actor TEXT NOT NULL, metadata TEXT, created_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    await v2.insert('staff', {
      'id': 's-1',
      'username': 'john',
      'pin_hash': 'hash',
      'name': 'John Doe',
      'active': 1,
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
    await v2.insert('audit_events', {
      'event_type': 'cashout',
      'actor': 'john',
      'metadata': '{"totalSales":350.0}',
      'created_at': DateTime(2026, 8, 29, 21).millisecondsSinceEpoch,
    });
    await v2.close();

    // --- reopen through the normal open path → triggers 2→3 upgrade ---
    final db3 = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    addTearDown(() => db3.close());

    expect(await db3.getVersion(), 3);
    await db3.rawQuery('SELECT * FROM cashout_logs'); // table now exists

    // Existing audit rows survived the CHECK-constraint table rebuild.
    expect(await db3.query('audit_events'), hasLength(1));

    // The widened CHECK admits the new event types.
    await db3.insert('audit_events', {
      'event_type': 'report_print',
      'actor': 'john',
      'created_at': DateTime(2026, 8, 29, 22).millisecondsSinceEpoch,
    });
    await db3.insert('audit_events', {
      'event_type': 'password_changed',
      'actor': 'john',
      'created_at': DateTime(2026, 8, 29, 23).millisecondsSinceEpoch,
    });
    await db3.insert('cashout_logs', {
      'waiter_id': 's-1',
      'waiter_username': 'john',
      'waiter_name': 'John Doe',
      'shift_start': DateTime(2026, 8, 29, 8).millisecondsSinceEpoch,
      'shift_end': DateTime(2026, 8, 29, 21).millisecondsSinceEpoch,
      'order_count': 12,
      'total_sales_cents': 35000,
      'cash_counted_cents': 35250,
      'cash_variance_cents': 250,
      'created_at': DateTime(2026, 8, 29, 21).millisecondsSinceEpoch,
    });
    expect(await db3.query('audit_events'), hasLength(3));
  });
}
