import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/cashout_record.dart';
import 'package:brewline/core/repositories/cashout_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_card.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Admin "Cashout log": one row per **finalized** shift close.
///
/// Unlike the Sales Log (a query over `orders`), each row here came from
/// `CashoutRepository.logCashout()` — the sole write path to `cashout_logs` —
/// so it is the authoritative point-in-time record of a shift: counted cash,
/// variance, and the order count/sales total captured at close time.
/// Interim preview prints never reach this table (§3.2 of the improve spec),
/// which is why a shift shows up here exactly once.
///
/// Filters (date window + waiter) push into the SQL `WHERE`; rows load 100 at
/// a time behind a "Load more" button, same as the sales log.
class CashoutLogsPage extends ConsumerStatefulWidget {
  const CashoutLogsPage({super.key});

  @override
  ConsumerState<CashoutLogsPage> createState() => _CashoutLogsPageState();
}

class _CashoutLogsPageState extends ConsumerState<CashoutLogsPage> {
  static const int _pageSize = 100;

  DateTimeRange? _range;
  String? _waiterUsername;

  List<CashoutRecord> _records = [];
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _records = [];
        _offset = 0;
        _hasMore = true;
      }
    });
    try {
      final repo = await ref.read(cashoutRepositoryProvider.future);
      final to =
          _range?.end; // picker end is inclusive → make the SQL range exclusive
      final rows = await repo.getCashoutLogs(
        from: _range?.start,
        to: to?.add(const Duration(days: 1)),
        waiterUsername: _waiterUsername,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _records = reset ? rows : [..._records, ...rows];
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
      currentDate: _range?.start ?? DateTime.now(),
      helpText: 'Filter cashouts by date',
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    await _load(reset: true);
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(
                'Cashout log',
                type: UiTextType.headlineSmall,
                fontWeight: FontWeight.w800,
              ),
              SizedBox(height: Space.xs),
              UiText(
                'Every finalized shift close, filterable by date or waiter.',
                type: UiTextType.bodyMedium,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: Space.xl),
          _buildFilters(context),
          SizedBox(height: Space.lg),
          if (_error != null)
            _message(context, 'Couldn\'t load the cashout log.')
          else if (_loading && _records.isEmpty)
            const _Loader()
          else if (_records.isEmpty)
            _message(context, 'No cashouts match these filters.')
          else ...[
            _CashoutTable(records: _records),
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

  /// Same single-line layout rule as the sales log filters.
  Widget _buildFilters(BuildContext context) {
    final staff = ref.watch(staffListProvider);

    void clearRange() {
      setState(() => _range = null);
      _load(reset: true);
    }

    return UiCard(
      title: 'Filters',
      leading: Icon(Icons.filter_list_rounded, color: Theme.of(context).colorScheme.primary),
      compact: true,
      content: Row(
        children: [
          Expanded(
            child: _DateFilterInput(
              range: _range,
              onTap: _pickRange,
              onClear: clearRange,
            ),
          ),
          SizedBox(width: Space.xl),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _waiterUsername,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Waiter',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All waiters')),
                for (final s in staff.value ?? [])
                  DropdownMenuItem(
                    value: s.username,
                    child: Text(s.name.isEmpty ? s.username : s.name),
                  ),
              ],
              onChanged: (value) {
                setState(() => _waiterUsername = value);
                _load(reset: true);
              },
            ),
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

/// Horizontally scrollable table of finalized [CashoutRecord] rows.
class _CashoutTable extends StatelessWidget {
  final List<CashoutRecord> records;

  const _CashoutTable({required this.records});

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
                DataColumn(label: Text('Date & Time')),
                DataColumn(label: Text('Orders Made')),
                DataColumn(label: Text('Waiter Name')),
                DataColumn(label: Text('Total Made')),
              ],
              rows: [
                for (final r in records)
                  DataRow(
                    cells: [
                      DataCell(Text(_dateTime(r.createdAt))),
                      DataCell(Text('${r.orderCount}')),
                      DataCell(Text(r.waiterName.isEmpty
                          ? r.waiterUsername
                          : r.waiterName)),
                      DataCell(Text(
                        formatPrice(r.totalSalesCents / 100),
                        style: TextStyle(fontWeight: FontWeight.w600),
                      )),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _dateTime(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year} · '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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