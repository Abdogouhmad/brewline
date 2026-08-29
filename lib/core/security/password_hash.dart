import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One-way hash used to protect stored PINs at rest.
///
/// PINs are never stored in plain text — only the SHA-256 digest is persisted
/// in SharedPreferences, and login compares the hash of the entered PIN. A
/// per-install salt could be layered on later; this keeps the dependency
/// footprint minimal while still avoiding plaintext credentials.
String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();
