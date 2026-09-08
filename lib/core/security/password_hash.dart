import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Returns a cryptographically random salt (hex-encoded, 128 bits).
///
/// Per-user salts prevent rainbow-table / precomputation attacks: even if two
/// users pick the same PIN, their stored hashes differ, and a leaked database
/// can't be brute-forced against a single shared digest.
String generateSalt() {
  final rng = Random.secure();
  return List.generate(
    16,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// One-way hash used to protect stored PINs at rest.
///
/// [salt] is the per-user (or per-install) hex salt. When [salt] is provided it
/// is mixed into the digest so identical PINs yield different hashes. Passing
/// `null` keeps legacy unsalted hashing so already-persisted PINs (created
/// before salting landed) continue to verify — new writes should always supply
/// a salt.
String hashPin(String pin, [String? salt]) {
  final input = salt == null || salt.isEmpty ? pin : '$salt:$pin';
  return sha256.convert(utf8.encode(input)).toString();
}
