import 'package:brewline/core/security/password_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateSalt', () {
    test('returns a 128-bit hex string', () {
      for (var i = 0; i < 20; i++) {
        final salt = generateSalt();
        expect(salt, matches(RegExp(r'^[0-9a-f]{32}$')));
      }
    });

    test('is unique across invocations', () {
      final salts = {for (var i = 0; i < 50; i++) generateSalt()};
      expect(salts.length, 50);
    });
  });

  group('hashPin', () {
    test('same PIN with different salts produces different hashes', () {
      expect(hashPin('1234', 'a' * 32), isNot(hashPin('1234', 'b' * 32)));
    });

    test('same salt + PIN is deterministic', () {
      expect(hashPin('1234', 'a' * 32), hashPin('1234', 'a' * 32));
    });

    test('null salt produces the legacy unsalted hash', () {
      expect(hashPin('1234', null), hashPin('1234'));
    });

    test('legacy unsalted hashes still verify against a null salt', () {
      final legacy = hashPin('1111');
      expect(hashPin('1111', null), legacy);
    });

    test('round-trips with a salt', () {
      final salt = generateSalt();
      final stored = hashPin('7777', salt);
      expect(hashPin('7777', salt), stored);
      expect(hashPin('7778', salt), isNot(stored));
    });
  });
}