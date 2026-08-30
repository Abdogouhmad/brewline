/// The two account roles a person can sign in as on a shared café device.
///
/// Used to branch the login form's validation/context and to route to the
/// matching dashboard. Extend here if staff roles are ever added.
enum Role {
  admin('Admin'),
  waiter('Waiter');

  const Role(this.label);

  /// Human-readable label for the role-switch control.
  final String label;
}
