import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/features/admin/providers/analytics_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'dashboard_card.dart';

/// Sales credited to each waiter in the period, ranked — the "team" read of
/// the reports tab. Also highlights who isn't contributing yet.
class TeamPerformance extends ConsumerWidget {
  const TeamPerformance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiters = ref.watch(waiterPerformanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: 'Team performance',
      icon: Icons.groups_outlined,
      child: waiters.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(Space.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _message(context, 'Couldn\'t load team sales.'),
        data: (items) {
          if (items.isEmpty) {
            return _message(context, 'No waiter-attributed sales this period.');
          }
          final maxRevenue = items.first.revenue;

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
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            child: UiText(
                              _initials(item),
                              type: UiTextType.labelSmall,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: Space.md),
                          Expanded(
                            child: UiText(
                              _displayName(item.username),
                              type: UiTextType.titleSmall,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: Space.md),
                          UiText(
                            '${item.orderCount} orders',
                            type: UiTextType.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: Space.md),
                          SizedBox(
                            width: 72,
                            child: UiText(
                              formatPrice(item.revenue),
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
                          value: (item.revenue / maxRevenue).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
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

  /// Username alone for now; Phase 2's Staff tab stores a display name we can
  /// join in later.
  static String _displayName(String username) => '@$username';

  static String _initials(WaiterSales sale) {
    final name = sale.username;
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
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
