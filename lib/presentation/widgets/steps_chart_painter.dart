import 'package:flutter/material.dart';
import '../../domain/entities/step_record_entity.dart';

/// High-performance zero-allocation CustomPainter for the Steps chart.
/// Renders bar chart buckets over time without generating Garbage Collection pressure.
class StepsChartPainter extends CustomPainter {
  final List<StepRecordEntity> records;
  final double? selectedNormalizedX;
  final Color primaryColor;
  final Color gridColor;

  // Pre-allocated static/reused Paint objects to ensure 0-allocation during paint()
  static final Paint _barPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  static final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  static final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..isAntiAlias = false;

  static final Paint _axisPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..isAntiAlias = true;

  StepsChartPainter({
    required this.records,
    this.selectedNormalizedX,
    this.primaryColor = const Color(0xFF00E5FF),
    this.gridColor = const Color(0x1FFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final width = size.width;
    final height = size.height;
    const paddingBottom = 24.0;
    const paddingTop = 16.0;
    final chartHeight = height - paddingBottom - paddingTop;

    // Draw horizontal gridlines
    _gridPaint.color = gridColor;
    const gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final y = paddingTop + (chartHeight / gridLines) * i;
      canvas.drawLine(Offset(0, y), Offset(width, y), _gridPaint);
    }

    // Baseline axis
    _axisPaint.color = gridColor.withValues(alpha: 0.3);
    canvas.drawLine(
      Offset(0, height - paddingBottom),
      Offset(width, height - paddingBottom),
      _axisPaint,
    );

    if (records.isEmpty) return;

    // Calculate max step count for scaling
    int maxCount = 1;
    for (final r in records) {
      if (r.count > maxCount) maxCount = r.count;
    }

    final barCount = records.length;
    final barSpacing = (width / barCount) * 0.25;
    final barWidth = (width / barCount) - barSpacing;

    _barPaint.color = primaryColor.withValues(alpha: 0.7);
    _highlightPaint.color = Colors.white;

    int? selectedIndex;
    if (selectedNormalizedX != null) {
      final normalized = selectedNormalizedX!.clamp(0.0, 1.0);
      selectedIndex = (normalized * (barCount - 1)).round();
    }

    for (int i = 0; i < barCount; i++) {
      final record = records[i];
      final barHeight = (record.count / maxCount) * chartHeight;
      final x = i * (barWidth + barSpacing) + (barSpacing / 2);
      final y = height - paddingBottom - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

      if (i == selectedIndex) {
        canvas.drawRRect(rrect, _highlightPaint);
      } else {
        canvas.drawRRect(rrect, _barPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StepsChartPainter oldDelegate) {
    return oldDelegate.records.length != records.length ||
        oldDelegate.selectedNormalizedX != selectedNormalizedX ||
        oldDelegate.primaryColor != primaryColor;
  }
}
