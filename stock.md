# Stock Management — Implementation Spec (Brewline / Café POS)

**Audience:** opencode coding agent
**Stack:** Flutter, Riverpod, `sqflite_common_ffi`
**Depends on:** `ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` (repository pattern, responsive shell, Sales Log pattern), `REFUND_SYSTEM_SPEC.md` (order voiding/editing — stock has to hook into both).
**Status:** Ready for implementation.

---

## 0. Summary of Changes

1. **Ingredients** — raw stock (coffee beans, milk, syrup, soda cans, cups, lids, etc.), each with a live quantity in a fixed smallest unit.
2. **Recipes** — a mapping from each product (Espresso, Latte, Soda, ...) to the ingredients + quantities it consumes per unit sold.
3. **Stock movements** — an immutable ledger of every quantity change (sale, refund restock, manual restock, waste), so the live quantity is always explainable and auditable.
4. Stock automatically **deducts on sale** and **restores on refund/void**, inside the same transactions those actions already use.
5. Admin screens: Ingredients list, Restock action, Recipe editor (attached to product editing), Stock Movements log, and a low-stock indicator on the dashboard/nav.

---

## 1. Data Model

### 1.1 Quantities as integers, not floats — same reasoning as money-in-cents
This project already stores money as integer cents specifically to avoid floating-point drift. Stock quantities get the same treatment: store every quantity as an **integer in its smallest sensible unit** — grams for weight, milliliters for volume, whole units for discrete items (cups, lids, cans). Never store stock as a `REAL`/`double`. Convert to a display-friendly form (e.g. grams → kg) only in the UI layer.

```sql
CREATE TABLE IF NOT EXISTS ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  unit TEXT NOT NULL CHECK (unit IN ('g', 'ml', 'unit')),
  current_stock INTEGER NOT NULL DEFAULT 0,       -- in `unit`'s smallest denomination, can go negative (see §3.2)
  reorder_threshold INTEGER NOT NULL DEFAULT 0,   -- triggers the low-stock indicator at/below this value
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS product_recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id),
  ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),
  quantity_per_unit INTEGER NOT NULL CHECK (quantity_per_unit > 0),  -- consumed per 1 unit of the product sold
  UNIQUE(product_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS stock_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),
  change_amount INTEGER NOT NULL,   -- negative = consumed, positive = added back
  reason TEXT NOT NULL CHECK (reason IN ('sale', 'refund_restock', 'restock', 'manual_adjustment', 'waste')),
  order_id INTEGER REFERENCES orders(id),  -- set when reason is 'sale' or 'refund_restock'
  admin_id INTEGER REFERENCES users(id),   -- set for manual actions: restock, manual_adjustment, waste
  note TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_stock_movements_ingredient_id ON stock_movements(ingredient_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_order_id ON stock_movements(order_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_created_at ON stock_movements(created_at);
CREATE INDEX IF NOT EXISTS idx_product_recipes_product_id ON product_recipes(product_id);
```

### 1.2 Why `current_stock` is a live column, not a derived query
Everywhere else in this project, the instinct has been "derive it, don't store it redundantly" (shift status, the Sales Log). Stock is the deliberate exception, and it's worth being explicit about why: `current_stock` gets read on **every single sale**, to check availability before a waiter completes an order — summing the entire `stock_movements` ledger on every add-to-cart tap would be needless, growing work for no benefit. So `current_stock` is a live, incrementally-updated number, and `stock_movements` is the audit ledger that explains how it got there — the same "fast live value + append-only audit trail" split already used for `cashout_logs` (a snapshot) alongside `audit_events` (the log). Both must always be updated together, in the same transaction — never one without the other.

### 1.3 Not every product needs a recipe
A product with no rows in `product_recipes` is treated as **untracked** — selling it doesn't touch stock at all. This is intentional, not a gap: some menu items (a flat service charge, a "misc" catch-all) genuinely shouldn't be tied to inventory. Don't require every product to have a recipe before it can be sold.

---

## 2. Repository Layer

```
lib/core/database/repositories/
  ingredient_repository.dart       // add/update/archive/getAll/getLowStock
  recipe_repository.dart           // getRecipeForProduct/setRecipe/removeIngredientFromProduct
  stock_movement_repository.dart   // logMovement/getMovements(filters)/restock/adjust
```

- `ingredient_repository.dart`: standard CRUD plus `getLowStock()` — `WHERE current_stock <= reorder_threshold AND is_archived = 0`, indexed scan, powers the dashboard indicator (§6).
- `recipe_repository.dart`: `getRecipeForProduct(productId)` returns the ingredient+quantity list for one product (used both by the recipe editor and, critically, by the sale-time deduction logic in §3.1 — same query, don't duplicate it).
- `stock_movement_repository.dart`: the **only** place that ever writes a row to `stock_movements` or mutates `ingredients.current_stock`. Every other repository that needs to touch stock (order creation, refunds) calls into this one rather than writing to those tables directly.

Archiving an ingredient (soft delete, same pattern as products) doesn't touch existing `product_recipes` or `stock_movements` rows — those stay for historical accuracy; just stop it from appearing in new recipe editing and restock UI.

---

## 3. Stock ⟷ Sales Integration

### 3.1 On order creation — deduct
`OrderRepository.create(...)` (from the admin dashboard spec) needs one addition, inside its existing transaction: after inserting each `order_item`, look up that product's recipe via `RecipeRepository.getRecipeForProduct(productId)`, and for each ingredient in it, call `StockMovementRepository.logMovement(ingredientId, changeAmount: -quantityPerUnit * itemQuantity, reason: 'sale', orderId: order.id)`, which itself updates `ingredients.current_stock` and inserts the `stock_movements` row in one place. This has to happen **in the same transaction** as the order/order_items insert — if the app crashes between "order saved" and "stock deducted," the two would drift out of sync, which defeats the entire point of this feature.

### 3.2 Insufficient stock — warn, don't block, by default
When a waiter is building an order and a product's tracked ingredients don't have enough `current_stock` to cover it, show a visible warning on that product's tile (e.g. an amber "Low stock" or red "Out of stock" badge) — but **allow the sale to complete anyway**, letting `current_stock` go negative. Reasoning: stock data can lag reality (a delivery that arrived but hasn't been logged yet), and hard-blocking a sale over a data-entry gap costs a real sale during a busy shift. A negative `current_stock` is itself a useful, visible signal to the admin that something needs reconciling — it's information, not an error state.

If you'd rather hard-block sales at zero/negative stock instead, that's a small change to this same check point — flag it back rather than assuming; it's a real product decision, not an obvious default.

### 3.3 On refund/void — restore
`RefundRepository` (from the refund spec) needs the mirror-image addition, in its existing transactions:
- **Partial refund** (`applyPartialRefund`): for each reduced/removed line item, call the same `StockMovementRepository.logMovement(...)` with a **positive** `changeAmount` (adding back what was originally deducted for the removed quantity), `reason: 'refund_restock'`, same `orderId`.
- **Full void** (`voidOrder`): restore the entire original order's recipe-derived quantities the same way.
- Same rule as §3.1: this must happen in the same transaction as the refund/void write, not as a separate follow-up step.

### 3.4 Products without a tracked recipe are unaffected
If a sold or refunded line item's product has no `product_recipes` rows, §3.1/§3.3 simply do nothing for that item — no error, no empty-loop side effects, just skip it.

---

## 4. Admin UI

### 4.1 Ingredients screen
- `lib/features/inventory/ingredients_page.dart` — list of ingredients: name, current stock (formatted per unit), low-stock badge if at/below threshold, archive action.
- Add/edit form: name, unit, reorder threshold. Editing unit after stock movements exist is a data-integrity foot-gun (a "g" ingredient with an established history suddenly reinterpreted as "unit") — lock the unit field on edit once any `stock_movements` rows reference that ingredient; only allow changing it while it's brand new and untouched.

### 4.2 Restock action
- `lib/features/inventory/widgets/restock_dialog.dart` — same responsive dialog(desktop)/bottom-sheet(mobile+tablet) pattern already established for refunds and OTA updates. Fields: quantity to add, required note (e.g. "Received 5kg from supplier"). Calls `StockMovementRepository.logMovement(..., reason: 'restock', adminId: ...)`.
- A second, similarly-shaped path for `waste`/`manual_adjustment` (spillage, breakage, stock count correction) — same dialog, a mode toggle, always requires a note since these are exactly the entries an admin will want explained later.

### 4.3 Recipe editor
- `lib/features/inventory/widgets/product_recipe_editor.dart`, embedded in the existing product add/edit form (not a separate top-level screen) — for the product being edited, a list of (ingredient, quantity-per-unit) rows with add/remove, backed by `RecipeRepository.setRecipe(productId, entries)`.

### 4.4 Stock Movements log
- `lib/features/inventory/stock_movements_log_page.dart` — same shape as the Sales Log and Cashout Logs screens (filter controls above, `DataTable2` below): filter by date range, ingredient, and reason; columns Date/Time, Ingredient, Change, Reason, Order # (if applicable), Note.
- Backed by `StockMovementRepository.getMovements(...)`, using the indexes from §1.1 — same "reuse the established filterable-log pattern" this project has now used three times (Sales Log, Cashout Logs, this one) — don't design a new list-screen shape for it.

---

## 5. Waiter-Facing Impact

The waiter-facing product grid (wherever orders are built) picks up the low/out-of-stock badge from §3.2 automatically once it reads from `ingredient_repository.getLowStock()` (or a per-product "is this sellable right now" check derived from its recipe) — waiters see the same warning admins see, since they're the ones who'd otherwise be surprised mid-order. No separate waiter-only stock screen is needed; they only need the badge, not the management tools.

---

## 6. Dashboard / Navigation Integration

- Add a small **Low Stock** summary card to the admin dashboard (same responsive card grid from the admin dashboard spec) showing a count of ingredients at/below their reorder threshold, tapping through to the Ingredients screen.
- Optional, matching the same "small dot on the nav destination" pattern already suggested for update-available in the OTA spec: a badge on the Inventory/Stock nav destination when `getLowStock()` is non-empty. Same mechanism, same reasoning — reuse it rather than inventing a second badge convention.

---

## 7. Documentation Requirements

- `stock_movement_repository.dart` gets a file-level comment stating plainly that it's the **only** writer of `ingredients.current_stock` and `stock_movements` — anything else in the codebase mutating either directly is a bug, not a shortcut.
- `order_repository.dart`'s `create()` and `refund_repository.dart`'s refund/void methods each get a one-line comment at the stock-touching step cross-referencing §3.1/§3.3, so the transactional coupling isn't accidentally split apart in a future edit.
- `ingredients_page.dart`'s unit-lock-after-first-movement rule (§4.1) gets a comment explaining why, since "why can't I just edit the unit" is exactly the kind of thing a future maintainer will otherwise "fix."

---

## 8. Acceptance Checklist

- [ ] Selling a product with a defined recipe deducts the correct quantity from every ingredient in that recipe, in the same transaction as the order write
- [ ] Selling a product with no recipe leaves all stock untouched
- [ ] Partial refund restores exactly the stock corresponding to the reduced/removed quantity, not the whole order
- [ ] Full void restores the entire original order's recipe-derived stock
- [ ] `current_stock` can go negative without error; the product tile shows a clear low/out-of-stock badge once at or below threshold
- [ ] Every `stock_movements` row has a correct, non-null `reason`, and `order_id`/`admin_id` are populated exactly where §1.1's table definition expects them
- [ ] Restock and waste/adjustment actions require a note and correctly update `current_stock`
- [ ] Recipe editor correctly attaches to product editing and persists via `RecipeRepository.setRecipe`
- [ ] Changing an ingredient's unit is blocked once it has any stock movement history
- [ ] Stock Movements log filters by date/ingredient/reason and matches the visual pattern of the Sales Log and Cashout Logs screens
- [ ] Dashboard Low Stock card shows an accurate count and links to the Ingredients screen
- [ ] No code outside `stock_movement_repository.dart` writes to `ingredients.current_stock` or `stock_movements` directly
