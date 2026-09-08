import 'dart:math';

/// Generates a cryptographically random hex suffix for a prefixed id.
///
/// Unlike a `DateTime.now().millisecondsSinceEpoch` suffix, this cannot
/// collide when two rows are created within the same millisecond (e.g. rapid
/// insertions or a copy-paste bug), which would otherwise violate the SQLite
/// primary key. Used for `staff-…` and `p-…` ids.
///
/// [prefix] becomes the id's human-readable prefix, e.g. `'staff'` →
/// `staff-a1b2c3d4`.
String generatePrefixedId(String prefix) {
  final rng = Random.secure();
  final hex = List.generate(
    16,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix-$hex';
}
