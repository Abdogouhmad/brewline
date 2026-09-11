import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'staff_form_sheet.dart';

/// Roster rendered as cards on phones/tablets and a [DataTable] on wide
/// screens. Inactive members drop to the bottom, greyed out, so the active
/// shift line-up is visible at a glance.
class StaffTable extends ConsumerWidget {
  const StaffTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffListProvider);

    return staff.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Center(
        child: UiText(
          AppLocalizations.of(context)!.staffTableError,
          type: UiTextType.bodyMedium,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(Space.x2l),
              child: UiText(
                AppLocalizations.of(context)!.staffTableEmpty,
                type: UiTextType.bodyMedium,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final sorted = [...members]
          ..sort((a, b) {
            if (a.active != b.active) return a.active ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1024) {
              return _StaffDataTable(members: sorted);
            }
            return Column(
              children: [
                for (final member in sorted)
                  Padding(
                    padding: EdgeInsets.only(bottom: Space.sm),
                    child: _StaffCard(member: member),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

String _initials(StaffMember member) {
  final parts = member.name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Overflow actions shared by both card and table rows.
PopupMenuButton<String> _rowMenu(
  BuildContext context,
  WidgetRef ref,
  StaffMember member,
) {
  final l10n = AppLocalizations.of(context)!;
  return PopupMenuButton<String>(
    tooltip: l10n.staffActionsTooltip,
    onSelected: (value) async {
      switch (value) {
        case 'edit':
          await showStaffFormSheet(context, member: member);
        case 'activate':
          await ref
              .read(staffMutationProvider.notifier)
              .setActive(member.id, true);
        case 'deactivate':
          if (await _confirmDeactivate(context, member)) {
            await ref
                .read(staffMutationProvider.notifier)
                .setActive(member.id, false);
          }
        case 'delete':
          if (await _confirmDelete(context, member)) {
            await ref.read(staffMutationProvider.notifier).delete(member.id);
          }
      }
    },
    itemBuilder: (_) => [
      PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
      if (member.active)
        PopupMenuItem(value: 'deactivate', child: Text(l10n.staffDeactivate))
      else
        PopupMenuItem(value: 'activate', child: Text(l10n.staffActivate)),
      PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
    ],
  );
}

Future<bool> _confirmDeactivate(
  BuildContext context,
  StaffMember member,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: UiText(
        l10n.staffDeactivateTitle(member.name),
        type: UiTextType.titleMedium,
      ),
      content: UiText(
        l10n.staffDeactivateBody,
        type: UiTextType.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.staffDeactivate),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> _confirmDelete(BuildContext context, StaffMember member) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: UiText(
        l10n.staffDeleteTitle(member.name),
        type: UiTextType.titleMedium,
      ),
      content: UiText(
        l10n.staffDeleteBody,
        type: UiTextType.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    if (context.mounted) {
      showUiSnackBar(
        context,
        l10n.staffDeletedSnackbar(member.name),
        type: UiSnackBarType.warning,
      );
    }
  }
  return confirmed ?? false;
}

Color _activeDotColor(BuildContext context, bool active) => active
    ? Theme.of(context).colorScheme.primary
    : Theme.of(context).colorScheme.outlineVariant;

class _StaffCard extends ConsumerWidget {
  final StaffMember member;

  const _StaffCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = member.active;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.xl),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isActive
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              foregroundColor: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              child: UiText(
                _initials(member),
                type: UiTextType.labelSmall,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    member.name,
                    type: UiTextType.titleSmall,
                    fontWeight: FontWeight.w600,
                    color: isActive ? null : colorScheme.onSurfaceVariant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  UiText(
                    '@${member.username}',
                    type: UiTextType.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isActive) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Space.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Rounded.xl),
                ),
                child: UiText(
                  l10n.staffInactive,
                  type: UiTextType.labelSmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: Space.xs),
            ],
            _rowMenu(context, ref, member),
          ],
        ),
      ),
    );
  }
}

class _StaffDataTable extends ConsumerWidget {
  final List<StaffMember> members;

  const _StaffDataTable({required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.xl),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: colorScheme.outlineVariant),
        child: DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columnSpacing: Space.x2l,
          horizontalMargin: Space.lg,
          headingRowColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHighest,
          ),
          headingTextStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          columns: [
            DataColumn(label: Text(l10n.staffColName)),
            DataColumn(label: Text(l10n.staffColUsername)),
            DataColumn(label: Text(l10n.staffColStatus)),
            DataColumn(label: Text(l10n.actionActions)),
          ],
          rows: [
            for (final (index, member) in members.indexed)
              DataRow(
                color: WidgetStatePropertyAll(
                  index.isOdd
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        )
                      : Colors.transparent,
                ),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: member.active
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          foregroundColor: member.active
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          child: UiText(
                            _initials(member),
                            type: UiTextType.labelSmall,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: Space.md),
                        UiText(
                          member.name,
                          type: UiTextType.titleSmall,
                          fontWeight: FontWeight.w600,
                          color: member.active
                              ? null
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    UiText(
                      '@${member.username}',
                      type: UiTextType.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Space.sm,
                        vertical: Space.xs,
                      ),
                      decoration: BoxDecoration(
                        color: member.active
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.4,
                              )
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(Rounded.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: _activeDotColor(context, member.active),
                          ),
                          SizedBox(width: Space.xs),
                          UiText(
                            member.active ? 'Active' : 'Inactive',
                            type: UiTextType.labelMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(_rowMenu(context, ref, member)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
