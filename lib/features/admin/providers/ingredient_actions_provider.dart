/// Admin ingredient write actions that pair a repository call with the
/// mutation-bump that lets every stock/ingredient reader refresh.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/repositories/ingredient_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';

/// Archives an ingredient and notifies every reader that the catalog changed.
///
/// Lives in a provider (not a widget closure) so the write path is testable
/// and reusable: `ref.read(ingredientArchiveProvider).archive(id)`. Readers
/// recompute through [ingredientMutationProvider].
class IngredientArchiveController {
  final Ref ref;

  const IngredientArchiveController(this.ref);

  Future<void> archive(int id) async {
    final repo = await ref.read(ingredientRepositoryProvider.future);
    await repo.archive(id);
    ref.read(ingredientMutationProvider.notifier).bump();
  }
}

final ingredientArchiveProvider = Provider<IngredientArchiveController>(
  (ref) => IngredientArchiveController(ref),
);