import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  group('product archive (soft delete)', () {
    late Database db;
    late ProductRepository repo;

    setUp(() async {
      db = await inMemoryDb();
      await deleteAllData(db);
      repo = ProductRepository(db);
      await repo.upsert(
        const Product(
          id: 'coffee-1',
          name: 'Espresso',
          price: 9,
          imagePath: '',
          category: 'Coffee',
          stockQuantity: 2,
          lowStockThreshold: 5,
        ),
      );
      await repo.upsert(
        const Product(
          id: 'drink-1',
          name: 'Cola',
          price: 15,
          imagePath: '',
          category: 'Soft drinks',
        ),
      );
    });

    tearDown(() => db.close());

    test('archive hides the product from all() and lowStock()', () async {
      expect((await repo.all()).map((p) => p.id), contains('coffee-1'));
      expect(
        await repo.lowStock(),
        hasLength(1),
      ); // coffee is at/below threshold

      await repo.archive('coffee-1');

      final catalog = await repo.all();
      expect(catalog.map((p) => p.id), isNot(contains('coffee-1')));
      expect(await repo.lowStock(), isEmpty);
    });

    test('upsert restores an archived product (re-add flow)', () async {
      await repo.archive('coffee-1');
      await repo.upsert(
        const Product(
          id: 'coffee-1',
          name: 'Espresso',
          price: 9,
          imagePath: '',
          category: 'Coffee',
          stockQuantity: 10,
          lowStockThreshold: 5,
        ),
      );

      expect((await repo.all()).map((p) => p.id), contains('coffee-1'));
    });

    test(
      'hard delete leaves nothing behind (test-only escape hatch)',
      () async {
        await repo.delete('drink-1');
        expect(await repo.byId('drink-1'), isNull);
        expect((await repo.all()).map((p) => p.id), isNot(contains('drink-1')));
      },
    );
  });
}
