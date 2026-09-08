/// Storage backend for the admin account's single credential triple
/// (username, salted PIN hash, salt).
///
/// On mobile (Android/iOS) the values live in the OS keychain via
/// `flutter_secure_storage` — protected against extraction during ADB
/// backups / developer sessions. On desktop (Windows/Linux), where there is no
/// equivalent keychain, they fall back to SharedPreferences so desktop builds
/// keep working without pulling in a libsecret/DPAPI dependency.
///
/// Both backends share the same key names and the same `AdminCredential`
/// payload, so callers never import a backend directly.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// SharedPreferences/secure-storage key holding the admin's username.
const String kAdminUsernameKey = 'admin_username';

/// Key holding the hashed admin PIN (see hashPin in `password_hash.dart`).
const String kAdminPinHashKey = 'admin_pin_hash';

/// Key holding the admin PIN's salt (per-install random salt, mixed into the
/// hash so a leaked store can't be rainbow-tabled).
const String kAdminPinSaltKey = 'admin_pin_salt';

/// The admin account's persisted identity: username + salted PIN hash.
class AdminCredential {
  final String username;
  final String pinHash;

  /// Salt mixed into [pinHash]. `null` for credentials created before salting
  /// landed — they verify against the legacy unsalted hash until changed.
  final String? pinSalt;

  const AdminCredential({
    required this.username,
    required this.pinHash,
    this.pinSalt,
  });
}

/// Backend-agnostic access to the admin [AdminCredential].
abstract class CredentialStore {
  /// Returns `null` when onboarding has not stored a credential yet.
  Future<AdminCredential?> read();

  Future<void> write(AdminCredential credential);

  /// Removes the stored credential (used by "reset business data").
  Future<void> clear();
}

/// OS-keychain-backed store for mobile platforms.
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore() : _storage = const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  @override
  Future<AdminCredential?> read() async {
    final username = await _storage.read(key: kAdminUsernameKey);
    final hash = await _storage.read(key: kAdminPinHashKey);
    // Salt may be absent for credentials created before salting landed; a
    // null salt keeps verifying against the legacy unsalted hash.
    final salt = await _storage.read(key: kAdminPinSaltKey);
    if (username == null || hash == null) return null;
    return AdminCredential(username: username, pinHash: hash, pinSalt: salt);
  }

  @override
  Future<void> write(AdminCredential credential) async {
    await Future.wait([
      _storage.write(key: kAdminUsernameKey, value: credential.username),
      _storage.write(key: kAdminPinHashKey, value: credential.pinHash),
      _storage.write(key: kAdminPinSaltKey, value: credential.pinSalt),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: kAdminUsernameKey),
      _storage.delete(key: kAdminPinHashKey),
      _storage.delete(key: kAdminPinSaltKey),
    ]);
  }
}

/// Plaintext-but-simple SharedPreferences backend for desktop platforms.
class PrefsCredentialStore implements CredentialStore {
  PrefsCredentialStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<AdminCredential?> read() async {
    final username = _prefs.getString(kAdminUsernameKey);
    final hash = _prefs.getString(kAdminPinHashKey);
    final salt = _prefs.getString(kAdminPinSaltKey);
    if (username == null || hash == null) return null;
    return AdminCredential(username: username, pinHash: hash, pinSalt: salt);
  }

  @override
  Future<void> write(AdminCredential credential) async {
    await _prefs.setString(kAdminUsernameKey, credential.username);
    await _prefs.setString(kAdminPinHashKey, credential.pinHash);
    final salt = credential.pinSalt;
    if (salt == null) {
      await _prefs.remove(kAdminPinSaltKey);
    } else {
      await _prefs.setString(kAdminPinSaltKey, salt);
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(kAdminUsernameKey);
    await _prefs.remove(kAdminPinHashKey);
    await _prefs.remove(kAdminPinSaltKey);
  }
}

/// Picks the secure (mobile) or prefs (desktop) store for the current platform.
///
/// Lives next to the store so auth/onboarding/settings code can `ref.read` one
/// provider instead of branching on the platform themselves.
///
/// Uses `Platform` (not `defaultTargetPlatform`): under `flutter test` the
/// target platform defaults to Android, which would route tests into the
/// secure-storage platform channel. `dart:io` reflects the real host, so host
/// tests stay on the prefs backend automatically.
final credentialStoreProvider = Provider<CredentialStore>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return SecureCredentialStore();
  }
  return PrefsCredentialStore(ref.watch(sharedPreferencesProvider));
});