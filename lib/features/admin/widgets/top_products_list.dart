import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/features/admin/providers/top_products_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'dashboard_card.dart';

/// Ranked best sellers within the selected period — the "what sells" card
/// that drives restocking and menu-pricing decisions.
class TopProductsList extends ConsumerWidget {
  const TopProductsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(topProductsProvider);

    return DashboardCard(
      title: 'Top products',
      icon: Icons.local_fire_department_outlined,
      trailing: null,
      child: products.when(
        loading: () => const _ComfyLoading(),
        error: (_, _) => _message(context, 'Couldn\'t load top products.'),
        data: (items) {
          if (items.isEmpty) {
            return _message(context, 'No sales recorded in this period.');
          }
          final maxQty = items.first.quantity;
          return Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _ProductRank(
                  rank: i + 1,
                  sold: items[i],
                  fractionOfTop: items[i].quantity / maxQty,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _message(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Space.xl),
      child: Center(
        child: UiText(
          text,
          type: UiTextType.bodyMedium,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ProductRank extends StatelessWidget {
  final int rank;
  final ProductSold sold;
  final double fractionOfTop;

  const _ProductRank({
    required this.rank,
    required this.sold,
    required this.fractionOfTop,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: Space.lg),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: UiText(
                  '$rank',
                  type: UiTextType.labelLarge,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: Space.sm),
              Expanded(
                child: UiText(
                  sold.name,
                  type: UiTextType.titleSmall,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              UiText(
                '${sold.quantity} sold',
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: Space.lg),
              SizedBox(
                width: 72,
                child: UiText(
                  formatPrice(sold.revenue),
                  type: UiTextType.labelLarge,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Rounded.full),
            child: LinearProgressIndicator(
              value: fractionOfTop.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComfyLoading extends StatelessWidget {
  const _ComfyLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Space.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
