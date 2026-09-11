import 'package:brewline/core/utils/date_format.dart';
import 'package:brewline/core/utils/price_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// §5 — locale-aware number/date formatting through intl.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('fr');
  });

  group('formatPriceCentsIn', () {
    test('English: symbol first, US grouping and decimals', () {
      expect(formatPriceCentsIn('en', 450), 'DH 4.50');
      expect(formatPriceCentsIn('en', 123450), 'DH 1,234.50');
      expect(formatPriceCentsIn('en', -150), 'DH -1.50');
      expect(formatPriceCentsIn('en', 0), 'DH 0.00');
    });

    test('French: symbol last, narrow-space grouping, comma decimals', () {
      expect(formatPriceCentsIn('fr', 450), '4,50\u00A0DH');
      expect(formatPriceCentsIn('fr', 123450), '1\u202F234,50\u00A0DH');
      expect(formatPriceCentsIn('fr', -150), '-1,50\u00A0DH');
      expect(formatPriceCentsIn('fr', 0), '0,00\u00A0DH');
    });
  });

  group('formatDateWithTimeIn', () {
    final d = DateTime(2026, 9, 5, 14, 30);

    test('English month names', () {
      expect(formatDateWithTimeIn('en', d), '5 Sep 2026 \u00b7 14:30');
    });

    test('French month names use abbreviated forms', () {
      expect(formatDateWithTimeIn('fr', d), '5 sept. 2026 \u00b7 14:30');
    });
  });

  group('formatDateShort', () {
    test('day-first compact date for both locales', () {
      expect(formatDateShort(DateTime(2026, 9, 5)), '5/9/2026');
    });
  });
}