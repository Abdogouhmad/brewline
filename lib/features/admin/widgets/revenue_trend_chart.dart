import 'package:flutter/material.dart';

import 'package:brewline/features/admin/providers/sales_trend_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';

/// Dependency-free bar chart of the revenue series, painted with
/// [CustomPainter] so no charting package is required.
///
/// Bars scale to the peak [TrendPoint.revenue], the tallest bar is emphasised
/// with the full primary colour (the rest are translucent), and only enough
/// x-axis labels are drawn to stay readable at the current width.
class RevenueTrendChart extends StatelessWidget {
  final List<TrendPoint> points;
  final double height;

  /// Formats the peak value label above the tallest bar. Defaults to a price
  /// (currency); reports pass an order-count formatter when the series isn't
  /// money (e.g. busiest hours).
  final String Function(double value) valueFormatter;

  const RevenueTrendChart({
    super.key,
    required this.points,
    this.height = 180,
    this.valueFormatter = formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
          points: points,
          barColor: colorScheme.primary,
          mutedBarColor: colorScheme.primary.withValues(alpha: 0.35),
          labelColor: colorScheme.onSurfaceVariant,
          gridColor: colorScheme.outlineVariant.withValues(alpha: 0.6),
          valueFormatter: valueFormatter,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<TrendPoint> points;
  final Color barColor;
  final Color mutedBarColor;
  final Color labelColor;
  final Color gridColor;
  final String Function(double value) valueFormatter;

  static const double _topPad = 12;
  static const double _bottomPad = 22;

  _BarChartPainter({
    required this.points,
    required this.barColor,
    required this.mutedBarColor,
    required this.labelColor,
    required this.gridColor,
    required this.valueFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final peak = points.fold<double>(
      0,
      (m, p) => p.revenue > m ? p.revenue : m,
    );
    final chartHeight = size.height - _topPad - _bottomPad;
    final slot = size.width / points.length;
    final barWidth = (slot * 0.6).clamp(4.0, 32.0).toDouble();
    final baselineY = size.height - _bottomPad;

    // Baseline so the chart reads as a series even with quiet days.
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );

    var highestIndex = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].revenue > points[highestIndex].revenue) highestIndex = i;
    }

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = slot * i + (slot - barWidth) / 2;
      final barHeight = peak <= 0 ? 0.0 : (point.revenue / peak) * chartHeight;

      if (barHeight > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, baselineY - barHeight, barWidth, barHeight),
          topLeft: Radius.circular(barWidth / 3),
          topRight: Radius.circular(barWidth / 3),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = i == highestIndex ? barColor : mutedBarColor,
        );
      }

      // Peak value label above the tallest bar.
      if (i == highestIndex && peak > 0) {
        _paintText(
          canvas,
          valueFormatter(peak),
          Offset(x + barWidth / 2, baselineY - barHeight - _topPad),
          color: barColor,
          anchor: _Anchor.bottomCenter,
          bold: true,
        );
      }
    }

    // X labels, only as many as fit comfortably.
    final labelEvery = points.length > 14 ? (points.length / 10).ceil() : 1;
    for (var i = 0; i < points.length; i += labelEvery) {
      final x = slot * i + slot / 2;
      _paintText(
        canvas,
        points[i].label,
        Offset(x, baselineY + 6),
        color: labelColor,
        anchor: _Anchor.topCenter,
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
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.barColor != barColor ||
      oldDelegate.valueFormatter != valueFormatter;
}

enum _Anchor { topCenter, bottomCenter }
