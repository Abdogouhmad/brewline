import 'package:brewline/features/admin/providers/analytics_provider.dart';
import 'package:brewline/features/admin/widgets/busiest_hours_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Full 7-day × 8-bucket grid with some activity, so sizing is exercised with
/// a real (non-empty) shape.
List<HeatmapCell> _fullGrid() => [
  for (var weekday = 0; weekday < 7; weekday++)
    for (var bucket = 0; bucket < 8; bucket++)
      HeatmapCell(
        weekday: weekday,
        bucketHour: 7 + bucket * 2,
        orders: bucket == 3 ? 12 : 2 + bucket,
      ),
];

void main() {
  testWidgets('heatmap reflows without horizontal overflow at phone widths', (
    tester,
  ) async {
    // 360, 390, 403 and 412 cover common phone widths (403 reproduced the
    // original 4px overflow).
    for (final width in const <double>[360, 390, 403, 412]) {
      tester.view.physicalSize = Size(width * 2, 900 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            busiestHoursHeatmapProvider.overrideWith((_) async => _fullGrid()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: BusiestHoursHeatmap()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'overflow at $width dp');
    }
  });
}
