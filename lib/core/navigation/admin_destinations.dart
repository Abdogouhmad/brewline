/// Single source of truth for the **admin** navigation destinations.
///
/// Spec root: `improve.md` §8 — the compact `NavigationBar`, the medium
/// `NavigationRail` and the expanded `NavigationDrawer` all derive their
/// labels/icons/order from [kAdminNavItems], so the destination list is never
/// duplicated across three nav widgets (or re-ordered in one place but not the
/// others).
library;

import 'package:flutter/material.dart';

/// One admin destination: identity ([id]), nav chrome ([label]/[icon]).
class AdminNavItem {
  final String id;
  final String label;
  final IconData icon;

  const AdminNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Ordered admin destinations.
///
/// Order matters twice: it's the order shown on the rail/drawer, and on
/// **compact** screens the first three are primary while the rest fold into
/// the "More" sheet (so lead with the destinations admins hit daily —
/// Dashboard, Reports, Menu — not with maintenance screens).
const List<AdminNavItem> kAdminNavItems = [
  AdminNavItem(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  AdminNavItem(id: 'reports', label: 'Reports', icon: Icons.bar_chart_outlined),
  AdminNavItem(id: 'menu', label: 'Menu', icon: Icons.restaurant_menu_outlined),
  AdminNavItem(id: 'staff', label: 'Staff', icon: Icons.people_outline),
  AdminNavItem(id: 'sales', label: 'Sales log', icon: Icons.receipt_long_outlined),
  AdminNavItem(
    id: 'cashout',
    label: 'Cashout log',
    icon: Icons.point_of_sale_outlined,
  ),
  AdminNavItem(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
  ),
];

/// Destinations that stay primary on compact (phone) navigation, in
/// [kAdminNavItems] order — everything after these joins the "More" sheet.
const int kCompactPrimaryCount = 3;
