import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../domain/entities/step_record_entity.dart';

/// High-performance zero-allocation CustomPainter for the Steps chart.
/// Renders generous daily weekly bars with clear day-of-week labels, compact
/// count headers, and an active glow on today's live steps.
class StepsChartPainter extends CustomPainter {
  final List<StepRecordEntity> records;
  final double? selectedNormalizedX;
  final Color primaryColor;
  final Color gridColor;

  // Pre-allocated static/reused Paint and TextPainter objects for zero GC pressure
  static final Paint _barPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  static final Paint _todayBarPaint = Paint()
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
    ..strokeWidth = 1.0
    ..isAntiAlias = true;

  static final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  StepsChartPainter({
    required this.records,
    this.selectedNormalizedX,
    this.primaryColor = const Color(0xFF00E5FF),
    this.gridColor = const Color(0x1FFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    developer.Timeline.timeSync('StepsChartPainter.paint', () {
      final width = size.width;
      final height = size.height;
      const paddingBottom = 28.0;
      const paddingTop = 22.0;
      final chartHeight = height - paddingBottom - paddingTop;

    // Draw horizontal gridlines
    _gridPaint.color = gridColor;
    const gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final y = paddingTop + (chartHeight / gridLines) * i;
      canvas.drawLine(Offset(0, y), Offset(width, y), _gridPaint);
    }

    // Baseline axis
    _axisPaint.color = gridColor.withValues(alpha: 0.35);
    canvas.drawLine(
      Offset(0, height - paddingBottom),
      Offset(width, height - paddingBottom),
      _axisPaint,
    );

    if (records.isEmpty) return;

    // Calculate max step count for scaling (minimum 8,000 for realistic 10k step goal perspective)
    int maxCount = 8000;
    for (final r in records) {
      if (r.count > maxCount) maxCount = r.count;
    }

    final barCount = records.length;
    final slotWidth = width / barCount;
    // For 7 bars, use ~52% of slot width for a chunky, readable bar (e.g. 26px on 350px width)
    final barWidth = barCount <= 10 ? (slotWidth * 0.52).clamp(18.0, 34.0) : (slotWidth * 0.75);

    _barPaint.color = primaryColor.withValues(alpha: 0.38);
    _todayBarPaint.color = primaryColor;
    _highlightPaint.color = Colors.white;

    int? selectedIndex;
    if (selectedNormalizedX != null) {
      final normalized = selectedNormalizedX!.clamp(0.0, 1.0);
      selectedIndex = (normalized * (barCount - 1)).round();
    }

    for (int i = 0; i < barCount; i++) {
      final record = records[i];
      final isToday = (i == barCount - 1);
      final isSelected = (i == selectedIndex);

      final slotCenterX = i * slotWidth + (slotWidth / 2);
      final barX = slotCenterX - (barWidth / 2);

      // If a day has 0 steps, leave it completely empty (no filled bar)
      if (record.count > 0) {
        final barHeight = math.max(6.0, (record.count / maxCount) * chartHeight);
        final barY = height - paddingBottom - barHeight;

        final rect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );

        if (isSelected) {
          canvas.drawRRect(rrect, _highlightPaint);
        } else if (isToday) {
          canvas.drawRRect(rrect, _todayBarPaint);
        } else {
          canvas.drawRRect(rrect, _barPaint);
        }

        // Draw compact step count text on top of the bar (e.g., "7.4k" or "436")
        if (barWidth >= 20) {
          final countStr = record.count >= 1000
              ? '${(record.count / 1000).toStringAsFixed(1)}k'
              : '${record.count}';

          _textPainter.text = TextSpan(
            text: countStr,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isToday
                      ? primaryColor
                      : Colors.white60,
              fontSize: 10,
              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          );
          _textPainter.layout();
          final textX = slotCenterX - (_textPainter.width / 2);
          final textY = math.max(2.0, barY - _textPainter.height - 3);
          _textPainter.paint(canvas, Offset(textX, textY));
        }
      } else if (isSelected) {
        // Subtle baseline marker when user inspects an empty day
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, height - paddingBottom - 2, barWidth, 2),
            const Radius.circular(1),
          ),
          _highlightPaint,
        );
      }

      // Draw X-axis Day of Week label below each bar
      String dayLabel;
      if (isToday) {
        dayLabel = 'Today';
      } else {
        dayLabel = DateFormat('E').format(record.startTime);
      }

      _textPainter.text = TextSpan(
        text: dayLabel,
        style: TextStyle(
          color: isToday
              ? primaryColor
              : isSelected
                  ? Colors.white
                  : record.count > 0
                      ? Colors.white60
                      : Colors.white24,
          fontSize: 11,
          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      );
      _textPainter.layout();
      final labelX = slotCenterX - (_textPainter.width / 2);
      final labelY = height - paddingBottom + 6.0;
      _textPainter.paint(canvas, Offset(labelX, labelY));
    }
    });
  }

  @override
  bool shouldRepaint(covariant StepsChartPainter oldDelegate) {
    if (oldDelegate.records.length != records.length) return true;
    if (oldDelegate.selectedNormalizedX != selectedNormalizedX) return true;
    if (oldDelegate.primaryColor != primaryColor) return true;
    if (records.isNotEmpty && oldDelegate.records.isNotEmpty) {
      if (oldDelegate.records.last.count != records.last.count) return true;
    }
    return false;
  }
}
