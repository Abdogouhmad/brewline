import 'package:flutter/material.dart';

import 'package:brewline/features/admin/providers/sales_trend_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';

/// Area-filled line chart of the revenue series, painted with [CustomPainter].
///
/// The polyline is stroked in the primary colour and filled edge-to-edge with
/// a soft primary gradient down to the baseline, keeping the "money over time"
/// reading without pulling in a chart package.
class RevenueLineChart extends StatelessWidget {
  final List<TrendPoint> points;
  final double height;

  const RevenueLineChart({super.key, required this.points, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          points: points,
          lineColor: colorScheme.primary,
          fillColor: colorScheme.primary.withValues(alpha: 0.18),
          gridColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
          labelColor: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<TrendPoint> points;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;

  static const double _topPad = 16;
  static const double _bottomPad = 24;

  _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final peak = points.fold<double>(
      0,
      (m, p) => p.revenue > m ? p.revenue : m,
    );
    final chartHeight = size.height - _topPad - _bottomPad;
    final baselineY = size.height - _bottomPad;
    final slot = size.width / (points.length - 1);

    Offset pointAt(int i) {
      final x = slot * i;
      final y = peak <= 0
          ? baselineY
          : baselineY - (points[i].revenue / peak) * chartHeight;
      return Offset(x, y);
    }

    // Horizontal gridlines with faint value labels at 0 / half / peak so the
    // line can be read without axis numbers jammed at every point.
    for (final fraction in const [0.25, 0.5, 0.75, 1.0]) {
      final y = baselineY - chartHeight * fraction;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }

    // Area fill under the line, faded toward the baseline.
    final fillPath = Path()..moveTo(pointAt(0).dx, baselineY);
    for (var i = 0; i < points.length; i++) {
      fillPath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    fillPath
      ..lineTo(pointAt(points.length - 1).dx, baselineY)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // The line itself.
    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Peak label above the highest point.
    final highestIndex = points.indexWhere((p) => p.revenue == peak);
    if (peak > 0 && highestIndex >= 0) {
      _paintText(
        canvas,
        formatPrice(peak),
        Offset(pointAt(highestIndex).dx, pointAt(highestIndex).dy - 10),
        anchor: _Anchor.bottomCenter,
        color: lineColor,
        bold: true,
      );
    }

    // Enough x labels to stay readable at any width.
    final labelEvery = points.length > 14 ? (points.length / 10).ceil() : 1;
    for (var i = 0; i < points.length; i += labelEvery) {
      _paintText(
        canvas,
        points[i].label,
        Offset(pointAt(i).dx, baselineY + 6),
        anchor: _Anchor.topCenter,
        color: labelColor,
        size: 10,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center, {
    required _Anchor anchor,
    Color color = Colors.black,
    double size = 11,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = switch (anchor) {
      _Anchor.topCenter => Offset(center.dx - painter.width / 2, center.dy),
      _Anchor.bottomCenter => Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height,
      ),
    };
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}

enum _Anchor { topCenter, bottomCenter }
