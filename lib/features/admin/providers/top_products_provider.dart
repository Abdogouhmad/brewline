import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/features/admin/providers/dashboard_period.dart';

/// Best sellers within the selected period, ranked by units sold — drives the
/// "Top products" dashboard card.
final topProductsProvider = FutureProvider<List<ProductSold>>((ref) async {
  final range = periodRange(ref.watch(dashboardPeriodProvider), DateTime.now());
  final journal = await ref.watch(orderJournalRepositoryProvider.future);
  ref.watch(journalMutationProvider);
  return journal.topProducts(range.from, range.to, limit: 5);
});
