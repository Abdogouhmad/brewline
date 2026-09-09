import 'package:flutter/material.dart';

import 'package:brewline/features/admin/providers/sales_trend_provider.dart';
import 'package:brewline/core/utils/price_format.dart';

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
  /// money (e.g. busiest hours). Values are integer cents.
  final String Function(int value) valueFormatter;

  const RevenueTrendChart({
    super.key,
    required this.points,
    this.height = 180,
    this.valueFormatter = formatPriceCents,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      width: double.infinity,
      // Belt-and-suspenders: the painter now clamps every label fully
      // inside the canvas, but clip anyway so nothing can ever bleed into
      // whatever sits above this chart.
      child: ClipRect(
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
  final String Function(int value) valueFormatter;

  // Reserves room above the tallest bar for its peak-value label.
  static const double _topPad = 26;
  static const double _bottomPad = 22;
  // Gap between the bar's top edge and the label sitting above it.
  static const double _labelGap = 4;

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

    final peak = points.fold<int>(0, (m, p) => p.revenue > m ? p.revenue : m);
    final chartHeight = size.height - _topPad - _bottomPad;
    final slot = size.width / points.length;
    final barWidth = (slot * 0.6).clamp(4.0, 32.0).toDouble();
    final baselineY = size.height - _bottomPad;

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

      // Peak value label above the tallest bar. Centered on the bar's x,
      // then clamped (inside _paintText) so it never runs past the canvas
      // edges — matters most when the peak bar sits near the left/right
      // side, e.g. an hourly series where only the current hour has data.
      if (i == highestIndex && peak > 0) {
        _paintText(
          canvas,
          valueFormatter(peak),
          Offset(x + barWidth / 2, baselineY - barHeight - _labelGap),
          canvasWidth: size.width,
          color: barColor,
          anchor: _Anchor.bottomCenter,
          bold: true,
        );
      }
    }

    final labelEvery = points.length > 14 ? (points.length / 10).ceil() : 1;
    for (var i = 0; i < points.length; i += labelEvery) {
      final x = slot * i + slot / 2;
      _paintText(
        canvas,
        points[i].label,
        Offset(x, baselineY + 6),
        canvasWidth: size.width,
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
    required double canvasWidth,
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

    var dx = center.dx - painter.width / 2;
    // Clamp horizontally so the label stays fully on-canvas even when its
    // anchor point (the bar it labels) sits close to an edge. Without this,
    // a wide label centered on a bar near the right side gets its tail cut
    // off — which is exactly what "DH 162" (missing ".00") was.
    final maxDx = canvasWidth - painter.width;
    dx = dx.clamp(0.0, maxDx < 0 ? 0.0 : maxDx);

    final dy = switch (anchor) {
      _Anchor.topCenter => center.dy,
      _Anchor.bottomCenter => center.dy - painter.height,
    };

    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.barColor != barColor ||
      oldDelegate.valueFormatter != valueFormatter;
}

enum _Anchor { topCenter, bottomCenter }
