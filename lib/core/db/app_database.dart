/// SQLite setup for brewline — the single database shared by the waiter POS
/// and the admin dashboards.
///
/// ## Schema
/// * `products` — catalog + stock. Columns also carry a soft-delete flag
///   (`is_archived`) and a local file path for gallery-picked photos
///   (`image_path`, may also point at a bundled `assets/` file).
/// * `orders` — journal header. `order_number` is the human-friendly,
///   per-day sequential number shown to customers; `id` stays the internal
///   ticket key. `is_voided` flags orders that have been fully voided.
/// * `order_items` — journal lines, snapshotted at charge time.
/// * `order_refunds` — refund records: one row per partial or full refund,
///   queryable and filterable on its own (not derived from audit_events).
/// * `staff` — POS accounts (waiters).
/// * `order_counters` — one row per calendar day holding the latest
///   `order_number`, so the next number is one atomic `UPDATE` away instead
///   of a `MAX()` scan. The "small" way to keep numbers sequential.
/// * `audit_events` — the session/cashout event log (login, logout, cashout,
///   report_print, password_changed, void, post_print_edit).
/// * `cashout_logs` — one row per *finalized* shift close, snapshotting the
///   counted cash + variance that can't be derived from `orders` alone.
/// * `ingredients` — raw stock items (beans, milk, cups…) with a live
///   quantity in a fixed smallest unit. `product_recipes` maps each product
///   to the ingredients it consumes per unit sold; `stock_movements` is the
///   append-only ledger explaining how each live quantity got there.
///
/// Small app preferences (auth, theme, onboarding) stay in SharedPreferences;
/// business data lives here.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:brewline/core/models/product.dart';

/// On-disk filename of the SQLite database.
const String kBrewlineDatabaseName = 'brewline.db';

/// Writable handle to the app database, opened once at startup.
///
/// `main()` (and tests) override this with an already-open instance so every
/// repository shares a single connection.
final appDatabaseProvider = FutureProvider<Database>(
  (ref) => openAppDatabase(),
);

/// Chooses the SQLite driver per platform: the bundled plugin on Android/iOS,
/// the FFI runtime everywhere else (Linux/Windows/macOS and tests).
DatabaseFactory databaseFactoryForPlatform() {
  if (Platform.isAndroid || Platform.isIOS) return databaseFactory;
  sqfliteFfiInit();
  return databaseFactoryFfi;
}

/// Opens (creating if needed) the brewline database.
///
/// [factory] and [path] are overridable so tests can open a clean in-memory
/// database instead of touching disc.
Future<Database> openAppDatabase({
  DatabaseFactory? factory,
  String? path,
}) async {
  final dbFactory = factory ?? databaseFactoryForPlatform();
  final dbPath =
      path ?? p.join(await dbFactory.getDatabasesPath(), kBrewlineDatabaseName);
  return dbFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      // Bump this when a schema change lands and add the matching
      // step to [kMigrations]. See the migration history below.
      version: 7,
      // Foreign keys are enabled *after* the upgrade transaction completes
      // (onOpen), not in onConfigure. PRAGMA foreign_keys is a silent no-op
      // inside a transaction, and migration 7 rebuilds the FK parents
      // (`orders`), which SQLite can't do while FKs are enforced. Keeping
      // them off during the upgrade lets the create→copy→drop→rename dance
      // run; onOpen re-enables enforcement for the app session so CASCADE
      // (order_items ↔ orders) and NO ACTION (order_refunds ↔ orders) still
      // hold. Drop/re-enable symmetry is why this lives in one callback.
      onUpgrade: _onUpgrade,
      onCreate: _onCreate,
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}

/// ## Migration history
/// | Version | Change |
/// |---------|--------|
/// | 1       | Initial schema: `products`, `orders`, `order_items`, `staff`. |
/// | 2       | `products.is_archived` soft delete; `orders.order_number`;
///            new `order_counters` (daily sequence) and `audit_events`
///            (login/logout/cashout) tables; lookup indexes for the
///            Sales Log + heatmap queries. |
/// | 3       | `cashout_logs` — one row per finalized shift close (counted
///            cash + variance, already derived order count/total at close
///            time); `audit_events.event_type` CHECK extended with
///            `report_print` (interim prints) and `password_changed`
///            (account updates) by table rebuild, data preserved. |
/// | 4       | `orders.is_voided` (soft-void flag for full refunds); new
///            `order_refunds` table (one row per partial/full refund);
///            `audit_events.event_type` CHECK widened with `void` and
///            `post_print_edit` (the refund fraud signals) by table rebuild,
///            data preserved. |
/// | 5       | Ingredient-level stock (§ stock.md): `ingredients` (live
///            quantities in a fixed smallest unit), `product_recipes` (per
///            product ingredient→quantity mapping), `stock_movements` (the
///            append-only ledger explaining how each live quantity got there). |
/// | 6       | Per-user PIN salts (§3 of the audit): `staff.pin_salt` holds a
///            per-user random salt mixed into the SHA-256 PIN hash. Existing
///            rows keep a NULL salt and still verify against the legacy
///            unsalted hash; new writes always set a salt. |
/// | 7       | Money as integer cents (§2 of the audit): `products.price`,
///            `orders.total` and `order_items.unit_price` are rebuilt into
///            `*_cents INTEGER` via ROUND(x * 100), dropping the float ever
///            representing DH. Runs with foreign keys off so the `orders`
///            parent rebuild can't trip its children's constraints; onOpen
///            re-enables them for the session. |
///
/// Keep this table up to date — it is the traceable record of every schema
/// change for `openAppDatabase()` callers (migration tests, feature dev).
const Map<int, List<String>> kMigrations = {
  2: [
    // Soft delete for products: historical order_items keep their snapshots
    // (they have no FK), so archiving preserves catalog + report integrity.
    'ALTER TABLE products ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
    // Human-friendly sequential number, assigned per day by the counter.
    'ALTER TABLE orders ADD COLUMN order_number INTEGER NOT NULL DEFAULT 0',
    'CREATE TABLE IF NOT EXISTS order_counters ('
        'date TEXT PRIMARY KEY,'
        'last_number INTEGER NOT NULL DEFAULT 0'
        ')',
    'CREATE TABLE IF NOT EXISTS audit_events ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        "event_type TEXT NOT NULL CHECK (event_type IN "
        "('login', 'logout', 'cashout')),"
        'actor TEXT NOT NULL,'
        'metadata TEXT,'
        'created_at INTEGER NOT NULL'
        ')',
  ],
  // 3 adds the finalized-shift ledger and widens the audit CHECK to admit
  // `report_print` (interim/preview prints are audit-only, not cashouts).
  // SQLite can't ALTER a CHECK constraint, so `audit_events` is rebuilt via
  // the standard create→copy→drop→rename dance.
  3: [
    'CREATE TABLE IF NOT EXISTS cashout_logs ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'waiter_id TEXT NOT NULL REFERENCES staff(id),'
        'waiter_username TEXT NOT NULL,'
        'waiter_name TEXT NOT NULL,'
        'shift_start INTEGER NOT NULL,'
        'shift_end INTEGER NOT NULL,'
        'order_count INTEGER NOT NULL,'
        'total_sales_cents INTEGER NOT NULL,'
        'cash_counted_cents INTEGER NOT NULL,'
        'cash_variance_cents INTEGER NOT NULL,'
        'created_at INTEGER NOT NULL'
        ')',
    'CREATE INDEX IF NOT EXISTS idx_cashout_logs_waiter_id '
        'ON cashout_logs(waiter_id)',
    'CREATE INDEX IF NOT EXISTS idx_cashout_logs_created_at '
        'ON cashout_logs(created_at)',
    'CREATE TABLE audit_events_new ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        "event_type TEXT NOT NULL CHECK (event_type IN "
        "('login', 'logout', 'cashout', 'report_print', 'password_changed')),"
        'actor TEXT NOT NULL,'
        'metadata TEXT,'
        'created_at INTEGER NOT NULL'
        ')',
    'INSERT INTO audit_events_new (id, event_type, actor, metadata, '
        'created_at) SELECT id, event_type, actor, metadata, created_at '
        'FROM audit_events',
    'DROP TABLE audit_events',
    'ALTER TABLE audit_events_new RENAME TO audit_events',
  ],
  // 4 adds the refund system: the soft-void flag on `orders`, the dedicated
  // `order_refunds` ledger, and two more audit event types (`void` and
  // `post_print_edit`) that already power the fraud-detection signals. The
  // audit CHECK is widened via the standard create→copy→drop→rename dance
  // since SQLite can't ALTER a CHECK constraint.
  4: [
    'ALTER TABLE orders ADD COLUMN is_voided INTEGER NOT NULL DEFAULT 0',
    'CREATE TABLE IF NOT EXISTS order_refunds ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'order_id INTEGER NOT NULL REFERENCES orders(id),'
        'admin_id TEXT NOT NULL,'
        "refund_type TEXT NOT NULL CHECK (refund_type IN ('partial', 'full')),"
        'amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),'
        'reason TEXT NOT NULL,'
        'created_at INTEGER NOT NULL'
        ')',
    'CREATE INDEX IF NOT EXISTS idx_order_refunds_order_id '
        'ON order_refunds(order_id)',
    'CREATE INDEX IF NOT EXISTS idx_order_refunds_created_at '
        'ON order_refunds(created_at)',
    'CREATE TABLE audit_events_new ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        "event_type TEXT NOT NULL CHECK (event_type IN "
        "('login', 'logout', 'cashout', 'report_print', 'password_changed', "
        "'void', 'post_print_edit')),"
        'actor TEXT NOT NULL,'
        'metadata TEXT,'
        'created_at INTEGER NOT NULL'
        ')',
    'INSERT INTO audit_events_new (id, event_type, actor, metadata, '
        'created_at) SELECT id, event_type, actor, metadata, created_at '
        'FROM audit_events',
    'DROP TABLE audit_events',
    'ALTER TABLE audit_events_new RENAME TO audit_events',
  ],
  // 5 adds ingredient-level stock management. Quantities are stored as
  // integers in the ingredient's smallest unit (grams/ml/whole units) to avoid
  // floating-point drift, mirroring how money is stored as integer cents.
  // `current_stock` is a live, incrementally-updated value read on every sale;
  // `stock_movements` is the append-only ledger (in the same transaction) that
  // explains it — see stock.md §1.
  5: [
    'CREATE TABLE IF NOT EXISTS ingredients ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'name TEXT NOT NULL,'
        "unit TEXT NOT NULL CHECK (unit IN ('g', 'ml', 'unit')),"
        'current_stock INTEGER NOT NULL DEFAULT 0,'
        'reorder_threshold INTEGER NOT NULL DEFAULT 0,'
        'is_archived INTEGER NOT NULL DEFAULT 0,'
        'created_at INTEGER NOT NULL'
        ')',
    'CREATE TABLE IF NOT EXISTS product_recipes ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'product_id TEXT NOT NULL REFERENCES products(id),'
        'ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),'
        'quantity_per_unit INTEGER NOT NULL CHECK (quantity_per_unit > 0),'
        'UNIQUE(product_id, ingredient_id)'
        ')',
    'CREATE TABLE IF NOT EXISTS stock_movements ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),'
        'change_amount INTEGER NOT NULL,'
        "reason TEXT NOT NULL CHECK (reason IN "
        "('sale', 'refund_restock', 'restock', 'manual_adjustment', 'waste')),"
        'order_id INTEGER REFERENCES orders(id),'
        'admin_id TEXT,'
        'note TEXT,'
        'created_at INTEGER NOT NULL'
        ')',
    'CREATE INDEX IF NOT EXISTS idx_stock_movements_ingredient_id '
        'ON stock_movements(ingredient_id)',
    'CREATE INDEX IF NOT EXISTS idx_stock_movements_order_id '
        'ON stock_movements(order_id)',
    'CREATE INDEX IF NOT EXISTS idx_stock_movements_created_at '
        'ON stock_movements(created_at)',
    'CREATE INDEX IF NOT EXISTS idx_product_recipes_product_id '
        'ON product_recipes(product_id)',
  ],
  // 6 adds per-user PIN salts. `pin_salt` is NULL for legacy rows; those
  // verify against the old unsalted hash until their PIN is next changed.
  6: [
    'ALTER TABLE staff ADD COLUMN pin_salt TEXT',
  ],
  // 7 migrates every money column from price floats to integer cents —
  // `products.price`, `orders.total`, `order_items.unit_price` become
  // `*_cents INTEGER`, rebuilt (with ROUND(x*100)) via the standard
  // create→copy→drop→rename dance. The audit's store-money-as-integer-cents
  // fix; see price_format.dart for the DH formatting that paired with it.
  // The whole migration runs with foreign keys OFF (see [openAppDatabase])
  // because `orders` is an FK parent, so no CASCADE fires while rebuilding.
  7: [
    // products — no table references it via FK, so a plain three-step rebuild.
    'CREATE TABLE products_new ('
        'id TEXT PRIMARY KEY,'
        'name TEXT NOT NULL,'
        'price_cents INTEGER NOT NULL,'
        'image_path TEXT NOT NULL,'
        "category TEXT NOT NULL DEFAULT '',"
        'available INTEGER NOT NULL DEFAULT 1,'
        'stock_quantity INTEGER NOT NULL DEFAULT 0,'
        'low_stock_threshold INTEGER NOT NULL DEFAULT 0,'
        'is_archived INTEGER NOT NULL DEFAULT 0'
        ')',
    'INSERT INTO products_new (id, name, price_cents, image_path, category, '
        'available, stock_quantity, low_stock_threshold, is_archived) '
        'SELECT id, name, CAST(ROUND(price * 100) AS INTEGER), image_path, '
        'category, available, stock_quantity, low_stock_threshold, '
        'is_archived FROM products',
    'DROP TABLE products',
    'ALTER TABLE products_new RENAME TO products',
    // order_items — must be dropped before `orders` is rebuilt: it is the
    // ON DELETE CASCADE child, so keeping it through the orders rebuild would
    // cascade-nuke its rows the moment `orders` is dropped.
    'CREATE TABLE order_items_new ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,'
        'product_id TEXT NOT NULL,'
        'name TEXT NOT NULL,'
        'quantity INTEGER NOT NULL,'
        'unit_price_cents INTEGER NOT NULL'
        ')',
    'INSERT INTO order_items_new (id, order_id, product_id, name, quantity, '
        'unit_price_cents) SELECT id, order_id, product_id, name, quantity, '
        'CAST(ROUND(unit_price * 100) AS INTEGER) FROM order_items',
    'DROP TABLE order_items',
    'ALTER TABLE order_items_new RENAME TO order_items',
    // orders — the FK parent. FKs are OFF during this migration (see
    // [openAppDatabase]), so dropping it can't trip the NO ACTION
    // constraints from `order_refunds` / `stock_movements`.
    'CREATE TABLE orders_new ('
        'id INTEGER PRIMARY KEY,'
        'created_at INTEGER NOT NULL,'
        'waiter_username TEXT,'
        'total_cents INTEGER NOT NULL,'
        'order_number INTEGER NOT NULL DEFAULT 0,'
        'is_voided INTEGER NOT NULL DEFAULT 0'
        ')',
    'INSERT INTO orders_new (id, created_at, waiter_username, total_cents, '
        'order_number, is_voided) SELECT id, created_at, waiter_username, '
        'CAST(ROUND(total * 100) AS INTEGER), order_number, is_voided '
        'FROM orders',
    'DROP TABLE orders',
    'ALTER TABLE orders_new RENAME TO orders',
  ],
};

/// Every lookup the dashboards actually run, indexed so the fast paths in
/// [OrderJournalRepository]/[SalesQueryRepository] stay fast:
/// date windows, waiter grouping, product history and audit lookups.
const List<String> _kIndexes = [
  'CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at)',
  'CREATE INDEX IF NOT EXISTS idx_orders_waiter_username '
      'ON orders(waiter_username)',
  'CREATE INDEX IF NOT EXISTS idx_orders_is_voided ON orders(is_voided)',
  'CREATE INDEX IF NOT EXISTS idx_order_items_product_id '
      'ON order_items(product_id)',
  'CREATE INDEX IF NOT EXISTS idx_order_items_order_id '
      'ON order_items(order_id)',
  'CREATE INDEX IF NOT EXISTS idx_audit_events_actor ON audit_events(actor)',
  'CREATE INDEX IF NOT EXISTS idx_cashout_logs_waiter_id '
      'ON cashout_logs(waiter_id)',
  'CREATE INDEX IF NOT EXISTS idx_cashout_logs_created_at '
      'ON cashout_logs(created_at)',
  'CREATE INDEX IF NOT EXISTS idx_order_refunds_order_id '
      'ON order_refunds(order_id)',
  'CREATE INDEX IF NOT EXISTS idx_order_refunds_created_at '
      'ON order_refunds(created_at)',
  'CREATE INDEX IF NOT EXISTS idx_stock_movements_ingredient_id '
      'ON stock_movements(ingredient_id)',
  'CREATE INDEX IF NOT EXISTS idx_stock_movements_order_id '
      'ON stock_movements(order_id)',
  'CREATE INDEX IF NOT EXISTS idx_stock_movements_created_at '
      'ON stock_movements(created_at)',
  'CREATE INDEX IF NOT EXISTS idx_product_recipes_product_id '
      'ON product_recipes(product_id)',
];

/// A *brand-new* database is created straight at the current schema (v3) via
/// [_createSchema] — migrations in [kMigrations] are **only** for [onUpgrade],
/// i.e. tables that already exist at an older version. Running both here
/// would double-apply ALTERs (`duplicate column name is_archived`).
Future<void> _onCreate(Database db, int version) async {
  await _createSchema(db);
  await _createIndexes(db);
  // No default catalog is seeded — a fresh install starts empty so the admin
  // enters their real products from zero.
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  final versions = kMigrations.keys.toList()..sort();
  for (final version in versions) {
    if (version > oldVersion && version <= newVersion) {
      for (final migration in kMigrations[version]!) {
        await db.execute(migration);
      }
    }
  }
  await _createIndexes(db);
}

/// Creates every table at the *current* schema (v4). Do not add columns here
/// for future versions — use [kMigrations] + [onUpgrade] instead.
Future<void> _createSchema(Database db) async {
  await db.execute('''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      price_cents INTEGER NOT NULL,
      image_path TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT '',
      available INTEGER NOT NULL DEFAULT 1,
      stock_quantity INTEGER NOT NULL DEFAULT 0,
      low_stock_threshold INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE orders (
      id INTEGER PRIMARY KEY,
      created_at INTEGER NOT NULL,
      waiter_username TEXT,
      total_cents INTEGER NOT NULL,
      order_number INTEGER NOT NULL DEFAULT 0,
      is_voided INTEGER NOT NULL DEFAULT 0
    )
  ''');
  // order_items.product_id intentionally has no FK — deleting a product must
  // not cascade into sales history (lines keep their name/price snapshots).
  await db.execute('''
    CREATE TABLE order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
      product_id TEXT NOT NULL,
      name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price_cents INTEGER NOT NULL
    )
  ''');
  // order_refunds: one row per partial/full refund. A dedicated table (not
  // an audit_events blob) because refunds need to be summed, filtered by date
  // and displayed as structured data (order id, amount, reason).
  // admin_id intentionally has no FK — the refunding account is the admin (or
  // a waiter) in SharedPreferences/staff, and like order_items.product_id we
  // avoid a cascading FK into history.
  await db.execute('''
    CREATE TABLE order_refunds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL REFERENCES orders(id),
      admin_id TEXT NOT NULL,
      refund_type TEXT NOT NULL CHECK (refund_type IN ('partial', 'full')),
      amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
      reason TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE staff (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      pin_hash TEXT NOT NULL,
      pin_salt TEXT,
      name TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE order_counters (
      date TEXT PRIMARY KEY,
      last_number INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE audit_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_type TEXT NOT NULL CHECK (event_type IN ('login', 'logout', 'cashout', 'report_print', 'password_changed', 'void', 'post_print_edit')),
      actor TEXT NOT NULL,
      metadata TEXT,
      created_at INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE cashout_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      waiter_id TEXT NOT NULL REFERENCES staff(id),
      waiter_username TEXT NOT NULL,
      waiter_name TEXT NOT NULL,
      shift_start INTEGER NOT NULL,
      shift_end INTEGER NOT NULL,
      order_count INTEGER NOT NULL,
      total_sales_cents INTEGER NOT NULL,
      cash_counted_cents INTEGER NOT NULL,
      cash_variance_cents INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  // Ingredient-level stock, mirroring money-in-cents: `current_stock` is the
  // live quantity stored as an integer in the ingredient's smallest unit; the
  // audit trail that explains it lives in `stock_movements`. Both are written
  // together, in the same transaction (stock.md §1.2).
  await db.execute('''
    CREATE TABLE ingredients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      unit TEXT NOT NULL CHECK (unit IN ('g', 'ml', 'unit')),
      current_stock INTEGER NOT NULL DEFAULT 0,
      reorder_threshold INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE product_recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id TEXT NOT NULL REFERENCES products(id),
      ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),
      quantity_per_unit INTEGER NOT NULL CHECK (quantity_per_unit > 0),
      UNIQUE(product_id, ingredient_id)
    )
  ''');
  await db.execute('''
    CREATE TABLE stock_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),
      change_amount INTEGER NOT NULL,
      reason TEXT NOT NULL CHECK (reason IN ('sale', 'refund_restock', 'restock', 'manual_adjustment', 'waste')),
      order_id INTEGER REFERENCES orders(id),
      admin_id TEXT,
      note TEXT,
      created_at INTEGER NOT NULL
    )
  ''');
}

Future<void> _createIndexes(Database db) async {
  for (final index in _kIndexes) {
    await db.execute(index);
  }
}

/// A starter catalog used by [seedDefaultProducts].
///
/// Not auto-inserted into the app anymore (the app starts empty; see
/// [_onCreate]) but kept so the repository tests can seed a known catalog
/// deterministically.
const List<Product> _defaultProducts = [
  Product(
    id: 'p-001',
    name: 'Espresso',
    priceCents: 900,
    imagePath: 'assets/stack_imgs/expresso.jpg',
    category: 'Coffee',
  ),
  Product(
    id: 'p-002',
    name: 'Coca-Cola',
    priceCents: 1500,
    imagePath: 'assets/stack_imgs/coca.jpg',
    category: 'Soft drinks',
  ),
  Product(
    id: 'p-003',
    name: 'Milk',
    priceCents: 900,
    imagePath: 'assets/stack_imgs/milk.jpg',
    category: 'Dairy',
  ),
  Product(
    id: 'p-004',
    name: 'Tea',
    priceCents: 900,
    imagePath: 'assets/stack_imgs/tea.jpg',
    category: 'Coffee',
  ),
  Product(
    id: 'p-005',
    name: 'Water',
    priceCents: 200,
    imagePath: 'assets/stack_imgs/water.png',
    category: 'Soft drinks',
  ),
];

/// Inserts [_defaultProducts] only when the `products` table is empty.
///
/// Test-only helper: production startup and [deleteAllData] no longer seed any
/// catalog, but the stock repository tests rely on a known default menu.
Future<void> seedDefaultProducts(Database db) async {
  final count =
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products'),
      ) ??
      0;
  if (count > 0) return;

  final batch = db.batch();
  for (final product in _defaultProducts) {
    batch.insert('products', product.toRow());
  }
  await batch.commit(noResult: true);
}

/// Wipes all business rows (used by "Reset onboarding" and tests), leaving a
/// truly empty database so the admin can set everything up from zero again.
///
/// Runs in a single transaction so a crash mid-reset can never leave the
/// database in a half-wiped state — either every table is cleared or none is.
Future<void> deleteAllData(Database db) async {
  await db.transaction((txn) async {
    for (final table in [
      'stock_movements',
      'product_recipes',
      'ingredients',
      'order_refunds',
      'order_items',
      'orders',
      'order_counters',
      'audit_events',
      'cashout_logs',
      'staff',
      'products',
    ]) {
      await txn.delete(table);
    }
  });
}
