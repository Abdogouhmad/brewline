import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/shift_status.dart';
import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/features/admin/providers/shift_status_provider.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'dashboard_card.dart';

/// Who is on shift and when each staff member tapped in / closed out.
///
/// The header confirms the signed-in admin's session is live (green dot) and
/// shows their account; the body lists every active waiter with a live
/// tick that says whether they are currently clocked in (green, with the
/// login time and elapsed duration) or clocked out (neutral, with the login
/// and last cash-out times), so a glance answers both "who runs the floor"
/// and "when did each shift start and end".
class ShiftStatusCard extends ConsumerWidget {
  const ShiftStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value;
    final username = session?.username;
    final shifts = ref.watch(shiftStatusProvider);

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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          SizedBox(height: Space.lg),
          shifts.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Padding(
              padding: EdgeInsets.symmetric(vertical: Space.sm),
              child: UiText(
                'Couldn\'t load shift status.',
                type: UiTextType.bodyMedium,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return UiText(
                  'No staff on the roster yet.',
                  type: UiTextType.bodyMedium,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    _StaffShiftRow(shift: list[i]),
                    if (i != list.length - 1) SizedBox(height: Space.md),
                  ],
                ],
              );
            },
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

/// One staff member's current shift summary: a live dot, the login time, and
/// either the elapsed duration (on shift) or the last cash-out time.
class _StaffShiftRow extends StatelessWidget {
  final ShiftStatus shift;

  const _StaffShiftRow({required this.shift});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onShift = shift.onShift;

    final (dotColor, statusText, detail) = onShift
        ? (
            Colors.green.shade600,
            'On shift',
            'Clocked in ${_formatTime(shift.checkIn)} · ${_elapsed(shift.checkIn)}',
          )
        : shift.checkIn != null
        ? (
            colorScheme.outlineVariant,
            'Clocked out',
            'Clocked in ${_formatTime(shift.checkIn)}'
                '${shift.lastCashOut != null ? ' · Cashed out ${_formatTime(shift.lastCashOut)}' : ''}',
          )
        : (colorScheme.outlineVariant, 'No shift yet', 'Never logged in');

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurfaceVariant,
              child: UiText(
                _initials(shift.name),
                type: UiTextType.labelMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surfaceContainerLow,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: UiText(
                      shift.name,
                      type: UiTextType.bodyMedium,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: Space.sm),
                  UiText(
                    statusText,
                    type: UiTextType.labelSmall,
                    fontWeight: FontWeight.w600,
                    color: onShift
                        ? Colors.green.shade700
                        : colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              SizedBox(height: Space.xs),
              UiText(
                detail,
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Local 12-hour time, e.g. `9:15 AM`.
  static String _formatTime(DateTime? at) {
    if (at == null) return '—';
    final local = at.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  /// Elapsed time on shift, e.g. `3h 20m`, `45m`.
  static String _elapsed(DateTime? since) {
    if (since == null) return '—';
    final diff = DateTime.now().difference(since.toLocal());
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours <= 0) return '${diff.inMinutes}m';
    return '${hours}h ${minutes}m';
  }
}
