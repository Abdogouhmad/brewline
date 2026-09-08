import 'package:brewline/core/utils/price_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPriceCents', () {
    test('formats whole amounts with two decimals', () {
      expect(formatPriceCents(900), 'DH 9.00');
    });

    test('formats fractional amounts', () {
      expect(formatPriceCents(450), 'DH 4.50');
      expect(formatPriceCents(2975), 'DH 29.75');
    });

    test('truncates sub-cent, rounds whole cents', () {
      expect(formatPriceCents(900), 'DH 9.00');
      expect(formatPriceCents(1000), 'DH 10.00');
    });

    test('handles zero and negative values', () {
      expect(formatPriceCents(0), 'DH 0.00');
      expect(formatPriceCents(-150), 'DH -1.50');
    });
  });
}