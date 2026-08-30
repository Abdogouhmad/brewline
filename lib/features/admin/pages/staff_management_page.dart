import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/features/admin/widgets/staff_form_sheet.dart';
import 'package:brewline/features/admin/widgets/staff_table.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Admin "Staff" tab: manage who can sign in to the POS.
///
/// Shows the roster (active first), a running active/total count and an
/// "Add staff" action that opens [showStaffFormSheet]. Every write goes
/// through [StaffRepository] and bumps the mutation counter so the shift
/// status card on the Dashboard reflects changes immediately.
class StaffManagementPage extends ConsumerWidget {
  const StaffManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 600
            ? Space.lg
            : Space.full,
        vertical: Space.lg,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    'Team',
                    type: UiTextType.headlineSmall,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: Space.xs),
                  const _TeamSummary(),
                ],
              ),
            ),
            UiButton(
              'Add staff',
              icon: Icons.person_add_alt_1_rounded,
              variant: UiButtonVariant.filled,
              onPressed: () => showStaffFormSheet(context),
            ),
          ],
        ),
        SizedBox(height: Space.xl),
        const StaffTable(),
      ],
    );
  }
}

/// Live "X active of Y" pill under the page title.
class _TeamSummary extends ConsumerWidget {
  const _TeamSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffListProvider);
    final text = switch (staff) {
      AsyncData(:final value) when value.isNotEmpty =>
        '${value.where((m) => m.active).length} of ${value.length} active',
      AsyncData() => 'Team is empty — add your first member',
      _ => 'Loading team…',
    };
    return UiText(
      text,
      type: UiTextType.bodyMedium,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
