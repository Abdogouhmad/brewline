import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/stock_movement.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/shared/ui/ui_card.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Admin "Stock movements log": a filterable history of every stock change —
/// the ledger that explains the live `current_stock` numbers.
///
/// Rows come straight from [StockMovementRepository.getMovements] (one indexed
/// LEFT JOIN over `stock_movements`/`ingredients`). Filters (all optional) push
/// into the SQL `WHERE`: a date window, an ingredient, and a movement reason.
class StockMovementsPage extends ConsumerStatefulWidget {
  const StockMovementsPage({super.key});

  /// Pushes this log as a full-screen page (it's a deep-dive view on top of
  /// the Inventory tab).
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StockMovementsPage()),
    );
  }

  @override
  ConsumerState<StockMovementsPage> createState() => _StockMovementsPageState();
}

class _StockMovementsPageState extends ConsumerState<StockMovementsPage> {
  DateTimeRange? _range;
  int? _ingredientId;
  StockMovementReason? _reason;

  List<StockMovement> _rows = [];
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(stockMovementRepositoryProvider.future);
      final rows = await repo.getMovements(
        StockMovementFilter(
          from: _range?.start,
          to: _range?.end.add(const Duration(days: 1)),
          ingredientId: _ingredientId,
          reason: _reason,
        ),
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
      helpText: 'Filter movements by date',
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock movements')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600
                ? Space.lg
                : Space.full,
            vertical: Space.lg,
          ),
          children: [
            UiText(
              'Every change to an ingredient\'s quantity, newest first.',
              type: UiTextType.bodyMedium,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: Space.lg),
            _buildFilters(context),
            SizedBox(height: Space.lg),
            if (_error != null)
              _message(context, 'Couldn\'t load the stock movements.')
            else if (_loading && _rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(Space.x3l),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rows.isEmpty)
              _message(context, 'No movements match these filters.')
            else
              _MovementsTable(rows: _rows),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final ingredients = ref.watch(allIngredientsProvider);

    return UiCard(
      title: 'Filters',
      leading: Icon(
        Icons.filter_list_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      compact: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date range',
              prefixIcon: Icon(Icons.date_range_outlined),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                _range == null
                    ? 'All dates'
                    : '${_fmt(_range!.start)} – ${_fmt(_range!.end)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _range == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear date filter',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        setState(() => _range = null);
                        _load();
                      },
                    ),
              onTap: _pickRange,
            ),
          ),
          SizedBox(height: Space.lg),
          DropdownButtonFormField<int?>(
            initialValue: _ingredientId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Ingredient',
              prefixIcon: Icon(Icons.eco_outlined),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All ingredients')),
              for (final i in ingredients.value ?? <Ingredient>[])
                DropdownMenuItem(
                  value: i.id,
                  child: Text(i.name),
                ),
            ],
            onChanged: (value) {
              setState(() => _ingredientId = value);
              _load();
            },
          ),
          SizedBox(height: Space.lg),
          DropdownButtonFormField<StockMovementReason?>(
            initialValue: _reason,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Reason',
              prefixIcon: Icon(Icons.more_horiz_rounded),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All reasons')),
              for (final r in StockMovementReason.values)
                DropdownMenuItem(
                  value: r,
                  child: Text(_reasonLabel(r)),
                ),
            ],
            onChanged: (value) {
              setState(() => _reason = value);
              _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Space.x3l),
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

  static String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _MovementsTable extends StatelessWidget {
  final List<StockMovement> rows;

  const _MovementsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(Rounded.md),
              ),
              columns: const [
                DataColumn(label: Text('When')),
                DataColumn(label: Text('Ingredient')),
                DataColumn(label: Text('Change')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Ref / note')),
              ],
              rows: [
                for (final row in rows)
                  DataRow(
                    cells: [
                      DataCell(Text(_dateTime(row.createdAt))),
                      DataCell(Text(row.ingredientName)),
                      DataCell(
                        Text(
                          '${row.changeAmount >= 0 ? '+' : ''}'
                          '${row.changeAmount} ${row.ingredientUnit.label}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: row.changeAmount >= 0
                                ? colorScheme.primary
                                : colorScheme.error,
                          ),
                        ),
                      ),
                      DataCell(_ReasonPill(reason: row.reason)),
                      DataCell(Text(_refNote(row))),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _refNote(StockMovement row) {
    if (row.orderId != null) return 'Order #${row.orderId}';
    return row.note?.isNotEmpty == true ? row.note! : '—';
  }

  static String _dateTime(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year} · '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _ReasonPill extends StatelessWidget {
  final StockMovementReason reason;

  const _ReasonPill({required this.reason});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (foreground, background) = switch (reason) {
      StockMovementReason.sale => (
        colorScheme.onPrimaryContainer,
        colorScheme.primaryContainer,
      ),
      StockMovementReason.refundRestock => (
        colorScheme.onTertiaryContainer,
        colorScheme.tertiaryContainer,
      ),
      StockMovementReason.restock => (
        colorScheme.onSecondaryContainer,
        colorScheme.secondaryContainer,
      ),
      StockMovementReason.manualAdjustment => (
        colorScheme.onSurface,
        colorScheme.surfaceContainerHighest,
      ),
      StockMovementReason.waste => (
        colorScheme.onErrorContainer,
        colorScheme.errorContainer,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: UiText(
        _label(reason),
        type: UiTextType.labelSmall,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    );
  }

  static String _label(StockMovementReason r) => switch (r) {
    StockMovementReason.sale => 'Sale',
    StockMovementReason.refundRestock => 'Refund',
    StockMovementReason.restock => 'Restock',
    StockMovementReason.manualAdjustment => 'Adjustment',
    StockMovementReason.waste => 'Waste',
  };
}

String _reasonLabel(StockMovementReason r) => switch (r) {
  StockMovementReason.sale => 'Sale',
  StockMovementReason.refundRestock => 'Refund / restock',
  StockMovementReason.restock => 'Restock',
  StockMovementReason.manualAdjustment => 'Manual adjustment',
  StockMovementReason.waste => 'Waste',
};

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
