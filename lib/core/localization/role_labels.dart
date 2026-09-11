import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/l10n/app_localizations.dart';

/// Localized labels for the two account roles.
///
/// The `Role` enum stays code-based (improve.md §4); display copy is resolved
/// per locale at the render sites that show a role badge.
extension RoleLabels on Role {
  String localizedLabel(AppLocalizations l10n) =>
      this == Role.admin ? l10n.roleAdmin : l10n.roleWaiter;
}

/// Same mapping for [UserProfile.role], which stores the enum's raw label
/// string rather than the enum itself.
String localizedRoleLabel(AppLocalizations l10n, String role) =>
    role == Role.admin.label ? l10n.roleAdmin : l10n.roleWaiter;