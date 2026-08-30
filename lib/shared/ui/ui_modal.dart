import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/responsive/responsive.dart';

/// Shows [content] as a **bottom sheet** on phones and tablets and as a centred
/// **dialog** on desktops (≥ 905dp), reusing the same widget either way — the
/// recommended pattern for add/edit forms on the admin dashboards.
///
/// ```dart
/// await showUiAdaptiveModal<void>(
///   context,
///   heightFactor: 0.92,
///   content: _MyForm(),
/// );
/// ```
Future<T?> showUiAdaptiveModal<T>(
  BuildContext context, {
  required Widget content,
  double heightFactor = 0.92,
  bool showDragHandle = true,
}) async {
  if (Responsive.isDesktop(context)) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Space.x2l,
          vertical: Space.x2l,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rounded.x2l),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(dialogContext).height,
          ),
          child: SingleChildScrollView(child: content),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: showDragHandle,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Rounded.x2l)),
    ),
    builder: (_) =>
        FractionallySizedBox(heightFactor: heightFactor, child: content),
  );
}

/// Padding for form bodies inside [showUiAdaptiveModal] content.
///
/// Sheets need extra bottom clearance so the on-screen keyboard doesn't cover
/// the submit button; dialogs are scrollable and only need breathing room.
///
/// ```dart
/// Padding(
///   padding: adaptiveModalPadding(context),
///   child: // ...form fields...
/// )
/// ```
EdgeInsets adaptiveModalPadding(BuildContext context) {
  final bottom = Responsive.isDesktop(context) ? Space.xl : Space.full;
  return EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, bottom);
}
