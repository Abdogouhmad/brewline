import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/core/repositories/sales_query_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_card.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Admin "Sales Log": a filterable, paginated line-level history of every
/// sale.
///
/// A UI feature only — the rows come from `SalesQueryRepository.getSales()`,
/// one indexed JOIN over `orders`/`order_items`/`staff`. There is **no**
/// parallel sales table in the database.
///
/// Filters (all optional) push into the SQL `WHERE`: a date window, a
/// product, and a waiter. Results load 100 at a time behind a "Load more"
/// button rather than an infinite-scroll listener, keeping the query bounded.
class SalesLogPage extends ConsumerStatefulWidget {
  const SalesLogPage({super.key});

  @override
  ConsumerState<SalesLogPage> createState() => _SalesLogPageState();
}

class _SalesLogPageState extends ConsumerState<SalesLogPage> {
  static const int _pageSize = 100;

  DateTimeRange? _range;
  String? _productId;
  String? _waiterUsername;

  List<SalesEntry> _entries = [];
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  /// Fetches a page. [reset] starts over from the top (filters changed);
  /// otherwise it appends the next page behind "Load more".
  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _entries = [];
        _offset = 0;
        _hasMore = true;
      }
    });
    try {
      final repo = await ref.read(salesQueryRepositoryProvider.future);
      final to =
          _range?.end; // picker end is inclusive → make the SQL range exclusive
      final rows = await repo.getSales(
        from: _range?.start,
        to: to?.add(const Duration(days: 1)),
        productId: _productId,
        waiterUsername: _waiterUsername,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _entries = reset ? rows : [..._entries, ...rows];
        _offset += rows.length;
        _hasMore = rows.length == _pageSize;
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
      // Anchor the calendar on the currently filtered (possibly old) window so
      // reopening the picker lands where the sales are instead of today's
      // month — "select old dates" without paging back month by month.
      currentDate: _range?.start ?? DateTime.now(),
      helpText: 'Filter sales by date',
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    await _load(reset: true);
  }

  void _clearRange() {
    setState(() => _range = null);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 600
              ? Space.lg
              : Space.full,
          vertical: Space.lg,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      'Sales log',
                      type: UiTextType.headlineSmall,
                      fontWeight: FontWeight.w800,
                    ),
                    SizedBox(height: Space.xs),
                    UiText(
                      'Every product line sold, filterable by date, '
                      'product or waiter.',
                      type: UiTextType.bodyMedium,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Space.xl),
          _buildFilters(context),
          SizedBox(height: Space.lg),
          if (_error != null)
            _message(context, 'Couldn\'t load the sales log.')
          else if (_loading && _entries.isEmpty)
            const _Loader()
          else if (_entries.isEmpty)
            _message(context, 'No sales match these filters.')
          else ...[
            _SalesTable(entries: _entries),
            if (_hasMore) ...[
              SizedBox(height: Space.lg),
              Center(
                child: UiButton(
                  'Load more',
                  icon: Icons.expand_more_rounded,
                  onPressed: _loading ? null : () => _load(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Narrowest comfortable width for one filter control. Kept small enough
  /// that tablets (≥ ~600dp content) fit all three filters on a single line.
  static const double _filterMinWidth = 190;

  Widget _buildFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final products = ref.watch(allProductsProvider);
    final staff = ref.watch(staffListProvider);

    return UiCard(
      title: 'Filters',
      leading: Icon(Icons.filter_list_rounded, color: colorScheme.primary),
      compact: true,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final filters = <Widget>[
            _DateFilterInput(
              range: _range,
              onTap: _pickRange,
              onClear: _clearRange,
            ),
            _buildProductFilter(products.value),
            _buildWaiterFilter(staff.value),
          ];
          final spacing = Space.xl;
          final fit = constraints.maxWidth >= 3 * _filterMinWidth + 2 * spacing;
          final fitsPair =
              constraints.maxWidth >= 2 * _filterMinWidth + spacing;

          if (fit) {
            // Wide enough for all three in one line, evenly sized.
            return Row(
              children: [
                for (final f in filters)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: f == filters.first ? 0 : spacing,
                      ),
                      child: f,
                    ),
                  ),
              ],
            );
          }
          if (fitsPair) {
            // Two on the first line, the third full-width below.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.only(right: spacing / 2),
                        child: filters[0],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.only(left: spacing / 2),
                        child: filters[1],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                filters[2],
              ],
            );
          }
          // Phone: one full-width filter per line.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in filters) ...[
                f,
                if (f != filters.last) SizedBox(height: spacing),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductFilter(List<Product>? products) {
    return DropdownButtonFormField<String?>(
      initialValue: _productId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Product',
        prefixIcon: Icon(Icons.local_cafe_outlined),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All products')),
        for (final p in products ?? [])
          DropdownMenuItem(value: p.id, child: Text(p.name)),
      ],
      onChanged: (value) {
        setState(() => _productId = value);
        _load(reset: true);
      },
    );
  }

  Widget _buildWaiterFilter(List<StaffMember>? staff) {
    return DropdownButtonFormField<String?>(
      initialValue: _waiterUsername,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Waiter',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All waiters')),
        for (final s in staff ?? [])
          DropdownMenuItem(
            value: s.username,
            child: Text(s.name.isEmpty ? s.username : s.name),
          ),
      ],
      onChanged: (value) {
        setState(() => _waiterUsername = value);
        _load(reset: true);
      },
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
}

/// Read-only date-window control that opens the range picker on tap.
class _DateFilterInput extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateFilterInput({
    required this.range,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Date range',
        prefixIcon: Icon(Icons.date_range_outlined),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          range == null
              ? 'All dates'
              : '${_formatDate(range!.start)} – ${_formatDate(range!.end)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: range == null
            ? null
            : IconButton(
                tooltip: 'Clear dates',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              ),
        onTap: onTap,
      ),
    );
  }

  static String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

/// Horizontally scrollable data table of [SalesEntry] rows.
class _SalesTable extends StatelessWidget {
  final List<SalesEntry> entries;

  const _SalesTable({required this.entries});

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
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Order #')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Waiter')),
                DataColumn(label: Text('Total')),
              ],
              rows: [
                for (final e in entries)
                  DataRow(
                    cells: [
                      DataCell(Text(_dateTime(e.createdAt))),
                      DataCell(Text(_orderNumber(e))),
                      DataCell(Text(e.productName)),
                      DataCell(Text('${e.quantity}')),
                      DataCell(Text(e.waiter)),
                      DataCell(Text(formatPrice(e.lineTotal))),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// `#007` for real counters; seed/historical rows fall back to the ticket id.
  static String _orderNumber(SalesEntry e) => e.orderNumber > 0
      ? '#${e.orderNumber.toString().padLeft(3, '0')}'
      : '#${e.orderId}';

  static String _dateTime(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year} · '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Space.x3l),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
