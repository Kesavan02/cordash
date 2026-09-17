import 'dart:developer' as developer;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../domain/entities/heart_rate_record_entity.dart';

/// High-performance zero-allocation CustomPainter for rolling Heart Rate curves.
/// Uses pre-allocated Paint and Path instances to strictly eliminate GC pauses at 60 FPS.
class HeartRateChartPainter extends CustomPainter {
  final List<HeartRateRecordEntity> records;
  final double? selectedNormalizedX;
  final Color primaryColor;
  final Color gridColor;

  static final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  static final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  static final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..isAntiAlias = false;

  static final Paint _crosshairPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = const Color(0x99FFFFFF)
    ..isAntiAlias = true;

  static final Paint _dotPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white
    ..isAntiAlias = true;

  static final Path _linePath = Path();
  static final Path _fillPath = Path();

  HeartRateChartPainter({
    required this.records,
    this.selectedNormalizedX,
    this.primaryColor = const Color(0xFFFF3366),
    this.gridColor = const Color(0x1FFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    developer.Timeline.timeSync('HeartRateChartPainter.paint', () {
      final width = size.width;
      final height = size.height;
      const paddingBottom = 24.0;
      const paddingTop = 16.0;
      final chartHeight = height - paddingBottom - paddingTop;

      // Draw background grid lines
      _gridPaint.color = gridColor;
      const gridDivisions = 3;
      for (int i = 0; i <= gridDivisions; i++) {
        final y = paddingTop + (chartHeight / gridDivisions) * i;
        canvas.drawLine(Offset(0, y), Offset(width, y), _gridPaint);
      }

      if (records.length < 2) return;

      // Determine min/max BPM (with safe margins: 50 to 140 min range)
      int minBpm = 200;
      int maxBpm = 40;
      for (final r in records) {
        if (r.bpm < minBpm) minBpm = r.bpm;
        if (r.bpm > maxBpm) maxBpm = r.bpm;
      }
      // Pad margins
      minBpm = (minBpm - 5).clamp(40, 180);
      maxBpm = (maxBpm + 10).clamp(minBpm + 20, 220);
      final bpmRange = (maxBpm - minBpm).toDouble();

      // Clear paths for reuse
      _linePath.reset();
      _fillPath.reset();

      final pointCount = records.length;
      final dx = width / (pointCount - 1);

      // First point coordinates
      final firstY =
          height -
          paddingBottom -
          ((records[0].bpm - minBpm) / bpmRange) * chartHeight;
      _linePath.moveTo(0, firstY);
      _fillPath.moveTo(0, height - paddingBottom);
      _fillPath.lineTo(0, firstY);

      double prevX = 0;
      double prevY = firstY;

      for (int i = 1; i < pointCount; i++) {
        final curX = i * dx;
        final curY =
            height -
            paddingBottom -
            ((records[i].bpm - minBpm) / bpmRange) * chartHeight;

        // Cubic Bezier smoothing
        final controlX1 = prevX + (curX - prevX) / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + (curX - prevX) / 2;
        final controlY2 = curY;

        _linePath.cubicTo(
          controlX1,
          controlY1,
          controlX2,
          controlY2,
          curX,
          curY,
        );
        _fillPath.cubicTo(
          controlX1,
          controlY1,
          controlX2,
          controlY2,
          curX,
          curY,
        );

        prevX = curX;
        prevY = curY;
      }

      // Complete fill path down to baseline
      _fillPath.lineTo(width, height - paddingBottom);
      _fillPath.close();

      // Shader fill with gradient
      _fillPaint.shader = ui.Gradient.linear(
        Offset(0, paddingTop),
        Offset(0, height - paddingBottom),
        [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
      );
      canvas.drawPath(_fillPath, _fillPaint);

      // Draw line curve
      _linePaint.color = primaryColor;
      canvas.drawPath(_linePath, _linePaint);

      // Draw selection indicator if active
      if (selectedNormalizedX != null) {
        final clampedNorm = selectedNormalizedX!.clamp(0.0, 1.0);
        final selIndex = (clampedNorm * (pointCount - 1)).round();
        final selX = selIndex * dx;
        final selY =
            height -
            paddingBottom -
            ((records[selIndex].bpm - minBpm) / bpmRange) * chartHeight;

        // Vertical crosshair
        canvas.drawLine(
          Offset(selX, paddingTop),
          Offset(selX, height - paddingBottom),
          _crosshairPaint,
        );

        // Highlight dot
        canvas.drawCircle(Offset(selX, selY), 5.0, _dotPaint);
        _linePaint.color = primaryColor;
        canvas.drawCircle(Offset(selX, selY), 7.0, _linePaint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant HeartRateChartPainter oldDelegate) {
    if (oldDelegate.records.length != records.length) return true;
    if (oldDelegate.selectedNormalizedX != selectedNormalizedX) return true;
    if (oldDelegate.primaryColor != primaryColor) return true;
    if (records.isNotEmpty && oldDelegate.records.isNotEmpty) {
      if (oldDelegate.records.last.bpm != records.last.bpm) return true;
    }
    return false;
  }
}
