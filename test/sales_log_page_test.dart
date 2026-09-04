import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/core/repositories/sales_query_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/features/admin/pages/sales_log_page.dart';
import 'package:brewline/features/admin/widgets/product_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub repository: returns canned sales rows without touching the database,
/// so the page's layout can be tested deterministically (the real query is
/// covered by `sales_query_repository_test.dart`).
class _StubSalesRepo implements SalesQueryRepository {
  @override
  Future<List<SalesEntry>> getSales({
    DateTime? from,
    DateTime? to,
    String? productId,
    String? waiterUsername,
    int limit = 100,
    int offset = 0,
  }) async {
    return [
      for (var i = 1; i <= 6; i++)
        SalesEntry(
          orderId: i,
          orderNumber: i,
          createdAt: DateTime(2026, 8, 30, 9 + i),
          productName: 'Espresso',
          quantity: 2,
          lineTotal: 18,
          waiterUsername: 'waiter1',
          waiterName: 'Amina',
        ),
    ];
  }

  @override
  Future<List<WeekdayHourCount>> ordersByWeekdayHour(
    DateTime from,
    DateTime to,
  ) {
    throw UnimplementedError();
  }
}

List<Product> _products() => const [
  Product(
    id: 'coffee-1',
    name: 'Espresso',
    price: 9,
    imagePath: '',
    category: 'Coffee',
  ),
  Product(
    id: 'drink-1',
    name: 'Cola',
    price: 15,
    imagePath: '',
    category: 'Soft drinks',
  ),
];

List<StaffMember> _staff() => [
  StaffMember(
    id: 's1',
    username: 'waiter1',
    pinHash: 'x',
    name: 'Amina',
    createdAt: DateTime(2026, 1, 1),
  ),
];

void main() {
  testWidgets(
    'sales log: table loads, filters align on one line, no overflow',
    (tester) async {
      for (final width in const [1200.0, 800.0, 412.0, 360.0]) {
        tester.view.physicalSize = Size(width * 2, 1000 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              salesQueryRepositoryProvider.overrideWith(
                (ref) async => _StubSalesRepo(),
              ),
              allProductsProvider.overrideWith((ref) async => _products()),
              staffListProvider.overrideWith((ref) async => _staff()),
            ],
            child: const MaterialApp(home: Scaffold(body: SalesLogPage())),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'overflow at $width');
        // Regression: the table used to stay hidden behind the forever-loading
        // spinner because `_loading` started true and `_load` bailed on its own
        // guard. Rows must actually render now.
        expect(
          find.text('Espresso'),
          findsWidgets,
          reason: 'row missing at $width',
        );

        // Filter order on every width: Date range, then Product, then Waiter.
        // Scoped to the filter card so the table's own 'Product'/'Waiter'
        // column headers don't collide. 'After' means same row and further
        // right, or wrapped onto a lower row.
        final filterCard = find.byType(Card);
        final labels = ['Date range', 'Product', 'Waiter'];
        final positions = <(double, double)>[];
        for (final label in labels) {
          final topLeft = tester.getTopLeft(
            find.descendant(of: filterCard, matching: find.text(label)),
          );
          positions.add((topLeft.dx, topLeft.dy));
        }
        for (var i = 1; i < labels.length; i++) {
          final (px, py) = positions[i - 1];
          final (cx, cy) = positions[i];
          final after = cy > py + 1 || (cy - py).abs() <= 1 && cx > px;
          expect(
            after,
            isTrue,
            reason:
                '${labels[i]} not after ${labels[i - 1]} at $width '
                '(${(px, py)} -> ${(cx, cy)})',
          );
        }
        // The filters sit on a single line whenever there's room (desktop and
        // tablets ≥ ~600dp content). Float labels sit a few px higher than
        // regular labels, so use a tolerance well under a full field height
        // (~56px+rungap).
        final sameRow = (positions[0].$2 - positions[2].$2).abs() < 20;
        if (width == 1200 || width == 800) {
          expect(
            sameRow,
            isTrue,
            reason: 'filters should share one row at $width',
          );
        }
      }
    },
  );

  testWidgets('add-product sheet has no horizontal overflow at any width', (
    tester,
  ) async {
    for (final width in const [412.0, 600.0, 768.0, 360.0]) {
      tester.view.physicalSize = Size(width * 2, 900 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          // The product form now embeds the ingredient-based RecipeEditor,
          // which watches `allIngredientsProvider`. Override it with an empty
          // catalog so this layout-only test renders without a real database.
          overrides: [
            allIngredientsProvider.overrideWith((ref) async => <Ingredient>[]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => showProductFormSheet(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'exception at $width');
      expect(find.text('Add product'), findsOneWidget);
      // Tear the sheet down fully so the next width starts from an empty
      // navigator (a leftover sheet would otherwise swallow the next tap).
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
}
