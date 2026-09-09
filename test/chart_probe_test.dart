import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewline/features/admin/providers/sales_trend_provider.dart';
import 'package:brewline/features/admin/widgets/revenue_trend_chart.dart';

Future<void> _snapshot(
  WidgetTester tester,
  double width,
  String name,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: const Key('shot'),
          child: Center(
            child: SizedBox(
              width: width,
              height: 180,
              child: RevenueTrendChart(
                points: const [
                  TrendPoint(label: '9', revenue: 2000),
                  TrendPoint(label: '10', revenue: 4500),
                  TrendPoint(label: '11', revenue: 12300),
                  TrendPoint(label: '12', revenue: 9000),
                  TrendPoint(label: '13', revenue: 15600),
                  TrendPoint(label: '14', revenue: 7800),
                  TrendPoint(label: '15', revenue: 4200),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('shot')),
  );
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('/tmp/opencode/chart_$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render chart at 320', (tester) async {
    await _snapshot(tester, 320, 'mobile');
  });

  testWidgets('render chart at 1199', (tester) async {
    await _snapshot(tester, 1199, 'desktop');
  });

  testWidgets('render chart at 220', (tester) async {
    await _snapshot(tester, 220, 'narrow');
  });
}