/// Shared building blocks for receipt templates.
///
/// Everything here is deliberately paper-agnostic: templates pick a
/// `PaperSize` + `LINE_WIDTH` pair and reuse these helpers for profile
/// loading, text sanitization and money/date formatting so the three
/// templates don't drift apart.
library;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Lazy, process-wide capability profile — `CapabilityProfile.load()` reads a
/// JSON asset, so we load it once and share it across every receipt.
CapabilityProfile? _profileCache;

/// The ESC/POS capability profile used by every template. Cached after the
/// first call; pass a fresh one into tests if the asset bundle isn't loaded.
Future<CapabilityProfile> defaultProfile() async {
  return _profileCache ??= await CapabilityProfile.load();
}

/// Resets the cached profile (tests that need a clean slate).
void resetProfileCache() => _profileCache = null;

/// Creates a `Generator` for [paper] pinned to [lineWidth] characters per
/// line.
///
/// `esc_pos_utils_plus` only ships `PaperSize` presets for 58/72/80mm, so a
/// 55mm or 88mm roll must express its width as an explicit
/// characters-per-line value. That value is what `Generator` uses for
/// alignment, rules and wrapping once set via `setGlobalFont` — which is why
/// every template documents its `LINE_WIDTH` constant instead of trusting the
/// enum.
Future<Generator> newPosGenerator({
  required PaperSize paper,
  required int lineWidth,
}) async {
  final generator = Generator(paper, await defaultProfile());
  generator.setGlobalFont(PosFontType.fontA, maxCharsPerLine: lineWidth);
  return generator;
}

/// Strips everything the printer's default Latin-1 code page can't encode so
/// `codec.encode` never throws on a non-ASCII catalog name (Arabic product
/// names currently print as `?` — rendering them properly needs a
/// CP1256-style code page, a separate improvement).
String posText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    buffer.write(rune > 255 ? '?' : String.fromCharCode(rune));
  }
  return buffer.toString();
}

/// Currency symbol used on printed receipts. Mirrors `price_format.dart`'s
/// `kCurrencySymbol` but lives in core so receipt code never imports a
/// feature layer.
const String kPosCurrencySymbol = 'DH ';

/// Formats integer cents as `12.34` / `-12.34` (variance can be negative).
String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}

/// Formats integer cents with the currency prefix, e.g. `DH 350.00`.
String formatCentsPrice(int cents) => '$kPosCurrencySymbol${formatCents(cents)}';

/// Compact receipt timestamp: `30 Aug 2026 14:32`.
String posDateTime(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]} ${dt.year} $hh:$mm';
}