import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/admin/providers/analytics_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'dashboard_card.dart';

/// Revenue mix by category — horizontal bars scaled to the top category, each
/// with its share of total revenue. Fastest visual read of "what do we sell?"
class CategoryMixBars extends ConsumerWidget {
  const CategoryMixBars({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(categoryMixProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: 'Category mix',
      icon: Icons.pie_chart_outline_rounded,
      child: mix.when(
        loading: () => const _PaddingLoader(),
        error: (_, _) => _message(context, 'Couldn\'t load the mix.'),
        data: (items) {
          if (items.isEmpty) {
            return _message(context, 'No sales recorded in this period.');
          }
          final total = items.fold<double>(0, (s, c) => s + c.revenue);
          final top = items.first.revenue;

          return Column(
            children: [
              for (final item in items)
                Padding(
                  padding: EdgeInsets.only(bottom: Space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: UiText(
                              item.category,
                              type: UiTextType.titleSmall,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          UiText(
                            formatPrice(item.revenue),
                            type: UiTextType.labelLarge,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                      SizedBox(height: Space.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Rounded.full),
                              child: LinearProgressIndicator(
                                value: (item.revenue / top).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          SizedBox(width: Space.sm),
                          UiText(
                            total <= 0
                                ? ''
                                : '${((item.revenue / total) * 100).round()}%',
                            type: UiTextType.labelSmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
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

class _PaddingLoader extends StatelessWidget {
  const _PaddingLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Space.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
