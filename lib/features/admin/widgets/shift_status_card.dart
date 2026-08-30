import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'dashboard_card.dart';

/// Who is on shift and how the team is staffed right now.
///
/// The header confirms the signed-in admin's session is live (green dot) and
/// shows their account; the footer gives the active/total roster as a count
/// plus a tiny progress bar, so a glance answers both "who runs the floor" and
/// "is anyone covering it?" in the same period the KPIs report on.
class ShiftStatusCard extends ConsumerWidget {
  const ShiftStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value;
    final username = session?.username;
    final staff = ref.watch(staffListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final activeCount = staff.value?.where((s) => s.active).length;
    final totalCount = staff.value?.length;
    final ratio = (totalCount == null || totalCount == 0)
        ? 0.0
        : activeCount! / totalCount;

    return DashboardCard(
      title: 'Shift status',
      icon: Icons.punch_clock_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: Space.xs),
          UiText(
            'On shift',
            type: UiTextType.labelMedium,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: UiText(
                  _initials(username),
                  type: UiTextType.titleMedium,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      'Signed in as',
                      type: UiTextType.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    UiText(
                      username ?? '—',
                      type: UiTextType.titleSmall,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (session != null) _roleBadge(context, session.role),
            ],
          ),
          SizedBox(height: Space.lg),
          Divider(height: 1, color: colorScheme.outlineVariant),
          SizedBox(height: Space.lg),
          Row(
            children: [
              UiText(
                'Team on shift',
                type: UiTextType.labelMedium,
                color: colorScheme.onSurfaceVariant,
              ),
              const Spacer(),
              UiText(
                activeCount == null
                    ? '—'
                    : '$activeCount of $totalCount active',
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w700,
                color: _teamColor(context, activeCount),
              ),
            ],
          ),
          SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Rounded.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: _progressColor(context, activeCount),
            ),
          ),
        ],
      ),
    );
  }

  /// `A` for `admin`, `W1` for `waiter1`, `?` when nobody is signed in.
  static String _initials(String? username) {
    if (username == null || username.isEmpty) return '?';
    final first = username[0].toUpperCase();
    final digits = username.replaceAll(RegExp(r'[^0-9]'), '');
    final second = digits.isNotEmpty ? digits[digits.length - 1] : '';
    return (first + second).toUpperCase();
  }

  /// Warm colours hint at teams that are short staffed on the floor.
  static Color? _teamColor(BuildContext context, int? activeCount) {
    if (activeCount == null) return null;
    final colorScheme = Theme.of(context).colorScheme;
    if (activeCount == 0) return colorScheme.error;
    if (activeCount <= 1) return colorScheme.tertiary;
    return null;
  }

  static Color _progressColor(BuildContext context, int? activeCount) {
    return _teamColor(context, activeCount) ??
        Theme.of(context).colorScheme.primary;
  }

  Widget _roleBadge(BuildContext context, Role role) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: UiText(
        role.label,
        type: UiTextType.labelMedium,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}
